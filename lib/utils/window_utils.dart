import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'mouse_detector.dart';

class WindowUtils {
  static bool _isCollapsed = false;
  static Timer? _fallbackTimer;
  static bool get isCollapsed => _isCollapsed;

  static Future<void> collapseWindow() async {
    if (_isCollapsed) return; // 如果已经收起，直接返回

    // 获取当前窗口位置和大小
    final currentPosition = await windowManager.getPosition();
    final currentSize = await windowManager.getSize();

    // 计算收起后的位置：保持窗口右上角位置不变
    // 收起后窗口大小为 50x50，所以新位置 = 原位置 + (原宽度 - 50)
    final newX = currentPosition.dx + (currentSize.width - 50);
    final newY = currentPosition.dy;

    // 先设置大小，再设置位置，确保窗口在正确位置
    await windowManager.setSize(const Size(50, 50));
    await windowManager.setPosition(Offset(newX, newY));
    // 最小化时使用 30% 透明度
    await windowManager.setOpacity(0.3);
    // 不忽略鼠标事件，以便能够检测鼠标进入和点击
    await windowManager.setIgnoreMouseEvents(false);
    // 确保窗口在最前面
    await windowManager.setAlwaysOnTop(true);

    // 最后更新状态，确保窗口操作完成后再更新
    _isCollapsed = true;
  }

  static Future<void> expandWindow() async {
    if (!_isCollapsed) return; // 如果已经展开，直接返回

    // 获取当前窗口位置
    final currentPosition = await windowManager.getPosition();

    // 计算展开后的位置：保持窗口右上角位置不变
    // 展开后窗口大小为 420x620，所以新位置 = 原位置 - (420 - 50)
    final newX = currentPosition.dx - (420 - 50);
    final newY = currentPosition.dy;

    // 先设置大小，再设置位置，确保窗口在正确位置
    await windowManager.setSize(const Size(420, 620));
    await windowManager.setPosition(Offset(newX, newY));
    // 展开时使用默认透明度
    await windowManager.setOpacity(0.95);
    await windowManager.setIgnoreMouseEvents(false);
    // 确保窗口在最前面
    await windowManager.setAlwaysOnTop(true);
    // 聚焦窗口
    await windowManager.focus();

    // 最后更新状态，确保窗口操作完成后再更新
    _isCollapsed = false;
  }

  static void startEdgeDetection({required VoidCallback onEdgeDetected}) {
    // 首先尝试使用平台通道进行精确检测
    MouseDetector.startEdgeDetection(
      onEdgeDetected: () {
        if (_isCollapsed) {
          onEdgeDetected();
        }
      },
      edgeThreshold: 10.0,
    );

    // 备用方案：检测窗口位置（如果平台通道不可用）
    _startFallbackDetection(onEdgeDetected);
  }

  static void _startFallbackDetection(VoidCallback onEdgeDetected) {
    _fallbackTimer?.cancel();
    // 备用方案：如果平台通道不可用，使用窗口鼠标事件检测
    // 当窗口设置为 ignoreMouseEvents 时，可以通过检测窗口区域的鼠标进入来激活
    // 但这种方法需要窗口能够接收鼠标事件，所以我们使用定时检测
    _fallbackTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) async {
        if (!_isCollapsed) return;

        try {
          // 尝试获取鼠标位置来检查平台通道是否可用
          final mousePos = await MouseDetector.getMousePosition();
          // 如果平台通道可用，主要检测逻辑已经在 MouseDetector 中处理
          // 这里只作为额外的备用检查
        } catch (e) {
          // 平台通道不可用，使用其他方法
          debugPrint('Mouse detection channel not available, using fallback');
        }
      },
    );
  }

  static void stopEdgeDetection() {
    MouseDetector.stopEdgeDetection();
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }
}
