import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import '../models/todo_category.dart';
import '../models/todo_item.dart';
import '../providers/overlay_provider.dart';
import '../providers/todo_provider.dart';

class OverlayTodoPanel extends StatefulWidget {
  const OverlayTodoPanel({super.key});

  @override
  State<OverlayTodoPanel> createState() => _OverlayTodoPanelState();
}

class _OverlayTodoPanelState extends State<OverlayTodoPanel> {
  late final FocusNode _focusNode;
  static const List<String> _weekdayLabels = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayProvider = context.watch<OverlayProvider>();
    final todoProvider = context.watch<TodoProvider>();
    TodoCategory? currentCategory;
    if (todoProvider.categories.isNotEmpty) {
      currentCategory = todoProvider.categories.firstWhere(
        (cat) => cat.id == todoProvider.currentCategoryId,
        orElse: () => todoProvider.categories.first,
      );
    }
    final categoryName = currentCategory?.name ?? '待办';

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          overlayProvider.hideOverlay();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(overlayProvider.overlayOpacity),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(categoryName),
                const SizedBox(height: 12),
                Expanded(child: _buildTodoList(todoProvider)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String categoryName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.push_pin, color: Colors.white, size: 16),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoList(TodoProvider provider) {
    final active = provider.activeTodos;

    if (active.isEmpty) {
      return Center(
        child: Text(
          '暂无待办事项',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: active
          .map((todo) => _OverlayTodoTile(todo: todo, dimmed: false))
          .toList(),
    );
  }
}

class _OverlayTodoTile extends StatelessWidget {
  final TodoItem todo;
  final bool dimmed;
  static const List<String> _weekdayLabels = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  const _OverlayTodoTile({
    required this.todo,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        dimmed ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.9);
    final priorityColor =
        dimmed ? todo.priority.color.withOpacity(0.4) : todo.priority.color;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(dimmed ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(dimmed ? 0.1 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            dimmed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: textColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        todo.title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          decoration: dimmed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.15),
                        border: Border.all(color: priorityColor, width: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        todo.priority.label,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _buildMeta(todo),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMeta(TodoItem todo) {
    final createdAt = todo.createdAt;
    final weekday = _weekdayLabels[(createdAt.weekday - 1) % 7];
    final time = DateFormat('MM-dd HH:mm').format(createdAt);
    return '$time $weekday';
  }
}
