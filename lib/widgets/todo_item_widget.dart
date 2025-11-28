import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';

class TodoItemWidget extends StatefulWidget {
  final TodoItem todo;

  const TodoItemWidget({super.key, required this.todo});

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<TodoItemWidget> {
  final TextEditingController _editController = TextEditingController();
  bool _isEditing = false;
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
    _editController.text = widget.todo.title;
  }

  @override
  void didUpdateWidget(covariant TodoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todo.id != widget.todo.id ||
        oldWidget.todo.title != widget.todo.title) {
      if (!_isEditing) {
        _editController.text = widget.todo.title;
      }
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _finishEditing(TodoProvider provider) {
    if (_isEditing) {
      provider.updateTodo(widget.todo.id, _editController.text);
      setState(() {
        _isEditing = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final weekday = _weekdayLabels[(date.weekday - 1) % 7];
    final time = DateFormat('MM-dd HH:mm').format(date);
    return '$time $weekday';
  }

  Future<void> _editNote(BuildContext context, TodoProvider provider) async {
    final controller = TextEditingController(text: widget.todo.note);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 640,
          height: 420,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: controller,
              expands: true,
              minLines: null,
              maxLines: null,
              autofocus: true,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: '输入备注内容',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      await provider.updateNote(widget.todo.id, result);
    }
  }

  void _showPriorityMenu(BuildContext context, TodoProvider provider) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy + size.height + 200,
      ),
      items: Priority.values.map((priority) {
        return PopupMenuItem<Priority>(
          value: priority,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: priority.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priority.label,
                style: TextStyle(
                  color:
                      widget.todo.priority == priority ? priority.color : null,
                  fontWeight: widget.todo.priority == priority
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedPriority) {
      if (selectedPriority != null &&
          selectedPriority != widget.todo.priority) {
        provider.updatePriority(widget.todo.id, selectedPriority);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Checkbox(
          value: widget.todo.completed,
          onChanged: (_) => provider.toggleTodo(widget.todo.id),
        ),
        title: Text(
          widget.todo.title,
          style: TextStyle(
            decoration: widget.todo.completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: widget.todo.completed ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showPriorityMenu(context, provider),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.todo.priority.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: widget.todo.priority.color,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.todo.priority.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.todo.priority.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '创建: ${_formatDate(widget.todo.createdAt)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            if (widget.todo.completed && widget.todo.completedAt != null)
              Text(
                '完成: ${_formatDate(widget.todo.completedAt!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[600],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note, size: 20),
              color: Colors.blueGrey[400],
              tooltip: '编辑备注',
              onPressed: () => _editNote(context, provider),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[300],
              onPressed: () => provider.deleteTodo(widget.todo.id),
            ),
          ],
        ),
        dense: true,
      ),
    );
  }
}
