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

  @override
  void initState() {
    super.initState();
    _editController.text = widget.todo.title;
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
                  color: widget.todo.priority == priority
                      ? priority.color
                      : null,
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
      if (selectedPriority != null && selectedPriority != widget.todo.priority) {
        provider.updatePriority(widget.todo.id, selectedPriority);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);
    final dateFormat = DateFormat('MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Checkbox(
          value: widget.todo.completed,
          onChanged: (_) => provider.toggleTodo(widget.todo.id),
        ),
        title: _isEditing
            ? TextField(
                controller: _editController,
                autofocus: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _finishEditing(provider),
                onEditingComplete: () => _finishEditing(provider),
              )
            : GestureDetector(
                onTap: _startEditing,
                child: Text(
                  widget.todo.title,
                  style: TextStyle(
                    decoration: widget.todo.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: widget.todo.completed
                        ? Colors.grey
                        : null,
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              '创建: ${dateFormat.format(widget.todo.createdAt)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            if (widget.todo.completed && widget.todo.completedAt != null)
              Text(
                '完成: ${dateFormat.format(widget.todo.completedAt!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[600],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: Colors.red[300],
          onPressed: () => provider.deleteTodo(widget.todo.id),
        ),
        dense: true,
      ),
    );
  }
}


