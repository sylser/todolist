import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口边框拖拽调整大小组件
/// 在窗口边缘添加可拖拽区域，支持调整窗口大小
class ResizeEdgeWidget extends StatelessWidget {
  final Widget child;
  final double edgeWidth;
  final double cornerSize;

  const ResizeEdgeWidget({
    super.key,
    required this.child,
    this.edgeWidth = 8.0,
    this.cornerSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主内容
        child,
        // 上边缘
        Positioned(
          top: 0,
          left: cornerSize,
          right: cornerSize,
          height: edgeWidth,
          child: _ResizeEdge(
            edgeType: _EdgeType.top,
          ),
        ),
        // 下边缘
        Positioned(
          bottom: 0,
          left: cornerSize,
          right: cornerSize,
          height: edgeWidth,
          child: _ResizeEdge(
            edgeType: _EdgeType.bottom,
          ),
        ),
        // 左边缘
        Positioned(
          top: cornerSize,
          bottom: cornerSize,
          left: 0,
          width: edgeWidth,
          child: _ResizeEdge(
            edgeType: _EdgeType.left,
          ),
        ),
        // 右边缘
        Positioned(
          top: cornerSize,
          bottom: cornerSize,
          right: 0,
          width: edgeWidth,
          child: _ResizeEdge(
            edgeType: _EdgeType.right,
          ),
        ),
        // 左上角
        Positioned(
          top: 0,
          left: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeEdge(
            edgeType: _EdgeType.topLeft,
          ),
        ),
        // 右上角
        Positioned(
          top: 0,
          right: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeEdge(
            edgeType: _EdgeType.topRight,
          ),
        ),
        // 左下角
        Positioned(
          bottom: 0,
          left: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeEdge(
            edgeType: _EdgeType.bottomLeft,
          ),
        ),
        // 右下角
        Positioned(
          bottom: 0,
          right: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeEdge(
            edgeType: _EdgeType.bottomRight,
          ),
        ),
      ],
    );
  }
}

enum _EdgeType {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _ResizeEdge extends StatefulWidget {
  final _EdgeType edgeType;

  const _ResizeEdge({
    required this.edgeType,
  });

  @override
  State<_ResizeEdge> createState() => _ResizeEdgeState();
}

class _ResizeEdgeState extends State<_ResizeEdge> {
  SystemMouseCursor _cursor = SystemMouseCursors.basic;
  Offset? _startMousePosition;
  Size? _startWindowSize;
  Offset? _startWindowPosition;

  @override
  void initState() {
    super.initState();
    _updateCursor();
  }

  void _updateCursor() {
    switch (widget.edgeType) {
      case _EdgeType.top:
      case _EdgeType.bottom:
        _cursor = SystemMouseCursors.resizeUpDown;
        break;
      case _EdgeType.left:
      case _EdgeType.right:
        _cursor = SystemMouseCursors.resizeLeftRight;
        break;
      case _EdgeType.topLeft:
      case _EdgeType.bottomRight:
        _cursor = SystemMouseCursors.resizeUpLeftDownRight;
        break;
      case _EdgeType.topRight:
      case _EdgeType.bottomLeft:
        _cursor = SystemMouseCursors.resizeUpRightDownLeft;
        break;
    }
  }

  Future<void> _onPanStart(DragStartDetails details) async {
    _startMousePosition = details.globalPosition;
    _startWindowSize = await windowManager.getSize();
    _startWindowPosition = await windowManager.getPosition();
  }

  Future<void> _onPanUpdate(DragUpdateDetails details) async {
    if (_startMousePosition == null || _startWindowSize == null || _startWindowPosition == null) return;

    final delta = details.globalPosition - _startMousePosition!;
    final minimumSize = const Size(300, 400);

    double newWidth = _startWindowSize!.width;
    double newHeight = _startWindowSize!.height;
    double newX = _startWindowPosition!.dx;
    double newY = _startWindowPosition!.dy;

    switch (widget.edgeType) {
      case _EdgeType.top:
        newHeight = (_startWindowSize!.height - delta.dy).clamp(minimumSize.height, double.infinity);
        newY = _startWindowPosition!.dy + (_startWindowSize!.height - newHeight);
        break;
      case _EdgeType.bottom:
        newHeight = (_startWindowSize!.height + delta.dy).clamp(minimumSize.height, double.infinity);
        break;
      case _EdgeType.left:
        newWidth = (_startWindowSize!.width - delta.dx).clamp(minimumSize.width, double.infinity);
        newX = _startWindowPosition!.dx + (_startWindowSize!.width - newWidth);
        break;
      case _EdgeType.right:
        newWidth = (_startWindowSize!.width + delta.dx).clamp(minimumSize.width, double.infinity);
        break;
      case _EdgeType.topLeft:
        newWidth = (_startWindowSize!.width - delta.dx).clamp(minimumSize.width, double.infinity);
        newHeight = (_startWindowSize!.height - delta.dy).clamp(minimumSize.height, double.infinity);
        newX = _startWindowPosition!.dx + (_startWindowSize!.width - newWidth);
        newY = _startWindowPosition!.dy + (_startWindowSize!.height - newHeight);
        break;
      case _EdgeType.topRight:
        newWidth = (_startWindowSize!.width + delta.dx).clamp(minimumSize.width, double.infinity);
        newHeight = (_startWindowSize!.height - delta.dy).clamp(minimumSize.height, double.infinity);
        newY = _startWindowPosition!.dy + (_startWindowSize!.height - newHeight);
        break;
      case _EdgeType.bottomLeft:
        newWidth = (_startWindowSize!.width - delta.dx).clamp(minimumSize.width, double.infinity);
        newHeight = (_startWindowSize!.height + delta.dy).clamp(minimumSize.height, double.infinity);
        newX = _startWindowPosition!.dx + (_startWindowSize!.width - newWidth);
        break;
      case _EdgeType.bottomRight:
        newWidth = (_startWindowSize!.width + delta.dx).clamp(minimumSize.width, double.infinity);
        newHeight = (_startWindowSize!.height + delta.dy).clamp(minimumSize.height, double.infinity);
        break;
    }

    await windowManager.setSize(Size(newWidth, newHeight));
    if (widget.edgeType == _EdgeType.top ||
        widget.edgeType == _EdgeType.left ||
        widget.edgeType == _EdgeType.topLeft ||
        widget.edgeType == _EdgeType.topRight ||
        widget.edgeType == _EdgeType.bottomLeft) {
      await windowManager.setPosition(Offset(newX, newY));
    }
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    _startMousePosition = null;
    _startWindowSize = null;
    _startWindowPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _cursor,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
}
