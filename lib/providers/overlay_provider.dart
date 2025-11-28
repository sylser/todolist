import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

enum OverlayAnchor {
  left,
  right;

  String get label {
    switch (this) {
      case OverlayAnchor.left:
        return '左上角';
      case OverlayAnchor.right:
        return '右上角';
    }
  }
}

class OverlayProvider with ChangeNotifier {
  static const String _opacityKey = 'overlay_opacity';
  static const String _anchorKey = 'overlay_anchor';

  bool _overlayVisible = false;
  double _overlayOpacity = 0.6;
  Size? _previousSize;
  Offset? _previousPosition;
  OverlayAnchor _anchor = OverlayAnchor.right;

  bool get isOverlayVisible => _overlayVisible;
  double get overlayOpacity => _overlayOpacity;
  OverlayAnchor get anchor => _anchor;

  OverlayProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _overlayOpacity = prefs.getDouble(_opacityKey) ?? 0.6;
      final anchorName = prefs.getString(_anchorKey);
      if (anchorName != null) {
        _anchor = OverlayAnchor.values.firstWhere(
          (value) => value.name == anchorName,
          orElse: () => OverlayAnchor.right,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载浮窗设置失败: $e');
    }
  }

  Future<void> setOpacity(double value) async {
    _overlayOpacity = value.clamp(0.2, 0.95);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_opacityKey, _overlayOpacity);
    } catch (e) {
      debugPrint('保存浮窗透明度失败: $e');
    }

    if (_overlayVisible) {
      await windowManager.setOpacity(_overlayOpacity);
    }
  }

  Future<void> setAnchor(OverlayAnchor anchor) async {
    _anchor = anchor;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_anchorKey, _anchor.name);
    } catch (e) {
      debugPrint('保存浮窗位置失败: $e');
    }

    if (_overlayVisible) {
      await _positionOverlayWindow();
    }
  }

  Future<void> showOverlay() async {
    if (_overlayVisible) return;

    _previousSize = await windowManager.getSize();
    _previousPosition = await windowManager.getPosition();

    await _positionOverlayWindow();

    await windowManager.setAlwaysOnTop(true);
    await windowManager.setOpacity(_overlayOpacity);
    await windowManager.setIgnoreMouseEvents(true, forward: true);

    _overlayVisible = true;
    notifyListeners();
  }

  Future<void> _positionOverlayWindow() async {
    const double overlayWidth = 320;
    const double overlayHeight = 420;
    const double padding = 20;

    final display = await ScreenRetriever.instance.getPrimaryDisplay();
    final screenSize = display.size;
    final visibleOrigin = display.visiblePosition ?? Offset.zero;

    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    double targetX;
    if (_anchor == OverlayAnchor.left) {
      targetX = visibleOrigin.dx + padding;
    } else {
      targetX = visibleOrigin.dx + screenWidth - overlayWidth - padding;
    }
    final targetY = visibleOrigin.dy + padding;

    await windowManager.setSize(const Size(overlayWidth, overlayHeight));
    await windowManager.setPosition(Offset(targetX, targetY));
  }

  Future<void> hideOverlay() async {
    if (!_overlayVisible) return;

    await windowManager.setIgnoreMouseEvents(false);
    await windowManager.setOpacity(0.95);

    if (_previousSize != null) {
      await windowManager.setSize(_previousSize!);
    }
    if (_previousPosition != null) {
      await windowManager.setPosition(_previousPosition!);
    }

    await windowManager.focus();

    _overlayVisible = false;
    notifyListeners();
  }
}
