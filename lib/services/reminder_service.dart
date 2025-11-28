import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';
import '../main.dart' as main_app;

class ReminderService {
  static Timer? _reminderTimer;
  static TodoProvider? _provider;

  /// 启动提醒服务
  static void start(TodoProvider provider) {
    _provider = provider;
    _startTimer();
  }

  /// 停止提醒服务
  static void stop() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
    _provider = null;
  }

  /// 启动定时器，每小时执行一次
  static void _startTimer() {
    _reminderTimer?.cancel();
    
    // 然后每小时执行一次
    _reminderTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) {
        _checkAndShowReminder();
      },
    );
  }

  /// 检查并显示提醒
  static Future<void> _checkAndShowReminder() async {
    if (_provider == null) return;

    // 获取所有未完成的紧急待办
    final urgentTodos = _provider!.todos
        .where((todo) => !todo.completed && todo.priority == Priority.urgent)
        .toList();

    if (urgentTodos.isEmpty) {
      return; // 没有紧急待办，不显示提醒
    }

    // 构建提醒消息
    final message = _buildReminderMessage(urgentTodos);

    // 使用 Windows 通知显示提醒
    await _showWindowsNotification(message);
  }

  /// 构建提醒消息
  static String _buildReminderMessage(List<TodoItem> urgentTodos) {
    if (urgentTodos.length == 1) {
      return '您有 1 个紧急待办事项：\n${urgentTodos[0].title}';
    } else {
      final titles = urgentTodos.take(5).map((todo) => '• ${todo.title}').join('\n');
      final more = urgentTodos.length > 5 ? '\n...还有 ${urgentTodos.length - 5} 个' : '';
      return '您有 ${urgentTodos.length} 个紧急待办事项：\n$titles$more';
    }
  }

  /// 显示 Windows 通知
  static Future<void> _showWindowsNotification(String message) async {
    try {
      // 尝试显示窗口并聚焦，让用户看到提醒
      await windowManager.show();
      await windowManager.focus();
      
      // 使用 Flutter 的 showDialog 显示提醒对话框
      final navigatorContext = main_app.navigatorKey.currentContext;
      if (navigatorContext != null) {
        showDialog(
          context: navigatorContext,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                const Text(
                  '紧急待办提醒',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('显示提醒失败: $e');
    }
  }
}

