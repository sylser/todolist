import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'mouse_detector.dart';

class WindowUtils {
  static bool _isCollapsed = false;
  static Timer? _fallbackTimer;
  static bool get isCollapsed => _isCollapsed;

  static Future<void> collapseWindow() async {
    _isCollapsed = true;
    
    // 先获取屏幕尺寸
    final screenSize = await MouseDetector.getScreenSize();
    double screenWidth = 1920; // 默认值
    if (screenSize != null) {
      screenWidth = screenSize.width;
    } else {
      // 备用方案：使用 Flutter 的 PlatformDispatcher 获取屏幕尺寸
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        final display = views.first;
        screenWidth = display.physicalSize.width / display.devicePixelRatio;
      }
    }
    
    // 设置窗口大小和位置
    await windowManager.setSize(const Size(50, 50));
    await windowManager.setPosition(
      Offset(screenWidth - 50, 0),
    );
    await windowManager.setOpacity(0.5);
    // 不忽略鼠标事件，以便能够检测鼠标进入和点击
    await windowManager.setIgnoreMouseEvents(false);
    // 确保窗口在最前面
    await windowManager.setAlwaysOnTop(true);
  }

  static Future<void> expandWindow() async {
    _isCollapsed = false;
    
    // 先获取屏幕尺寸
    final screenSize = await MouseDetector.getScreenSize();
    double screenWidth = 1920; // 默认值
    if (screenSize != null) {
      screenWidth = screenSize.width;
    } else {
      // 备用方案：使用 Flutter 的 PlatformDispatcher 获取屏幕尺寸
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        final display = views.first;
        screenWidth = display.physicalSize.width / display.devicePixelRatio;
      }
    }
    
    // 设置窗口大小和位置
    await windowManager.setSize(const Size(350, 500));
    await windowManager.setPosition(
      Offset(screenWidth - 350, 0),
    );
    await windowManager.setOpacity(0.95);
    await windowManager.setIgnoreMouseEvents(false);
    // 确保窗口在最前面
    await windowManager.setAlwaysOnTop(true);
    // 聚焦窗口
    await windowManager.focus();
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

