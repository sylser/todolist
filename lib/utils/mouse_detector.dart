import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class MouseDetector {
  static const MethodChannel _channel = MethodChannel('com.todolist/mouse');

  static Timer? _detectionTimer;
  static Function()? _onEdgeDetected;

  static Future<Offset?> getMousePosition() async {
    try {
      final result = await _channel.invokeMethod('getMousePosition');
      if (result != null) {
        final Map<dynamic, dynamic> position = result as Map;
        return Offset(
          (position['x'] as num).toDouble(),
          (position['y'] as num).toDouble(),
        );
      }
    } catch (e) {
      // 平台通道不可用时返回 null，将使用备用方案
      return null;
    }
    return null;
  }

  static Future<Size?> getScreenSize() async {
    try {
      final result = await _channel.invokeMethod('getScreenSize');
      if (result != null) {
        final Map<dynamic, dynamic> size = result as Map;
        return Size(
          (size['width'] as num).toDouble(),
          (size['height'] as num).toDouble(),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static void startEdgeDetection({
    required VoidCallback onEdgeDetected,
    double edgeThreshold = 10.0, // 边缘检测阈值（像素）
  }) {
    _onEdgeDetected = onEdgeDetected;
    _detectionTimer?.cancel();
    
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (timer) async {
        final mousePos = await getMousePosition();
        final screenSize = await getScreenSize();

        if (mousePos != null && screenSize != null) {
          // 检测鼠标是否在屏幕右侧边缘
          if (mousePos.dx >= screenSize.width - edgeThreshold && mousePos.dx <= screenSize.width) {
            _onEdgeDetected?.call();
          }
        }
      },
    );
  }

  static void stopEdgeDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _onEdgeDetected = null;
  }
}

