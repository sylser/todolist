import 'package:flutter/material.dart';

enum Priority {
  urgent,    // 紧急
  normal,    // 一般
  low,       // 不紧急
  pending,   // 待定
}

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.urgent:
        return '紧急';
      case Priority.normal:
        return '一般';
      case Priority.low:
        return '不紧急';
      case Priority.pending:
        return '待定';
    }
  }

  int get order {
    switch (this) {
      case Priority.urgent:
        return 0;
      case Priority.normal:
        return 1;
      case Priority.low:
        return 2;
      case Priority.pending:
        return 3;
    }
  }

  Color get color {
    switch (this) {
      case Priority.urgent:
        return Colors.red;
      case Priority.normal:
        return Colors.orange;
      case Priority.low:
        return Colors.blue;
      case Priority.pending:
        return Colors.grey;
    }
  }
}

class TodoItem {
  final String id;
  final String title;
  final DateTime createdAt;
  final bool completed;
  final Priority priority;

  TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.completed = false,
    this.priority = Priority.normal,
  });

  TodoItem copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    bool? completed,
    Priority? priority,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'completed': completed,
      'priority': priority.name,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    Priority priority = Priority.normal;
    if (json['priority'] != null) {
      try {
        priority = Priority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => Priority.normal,
        );
      } catch (e) {
        priority = Priority.normal;
      }
    }
    
    return TodoItem(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      completed: json['completed'] ?? false,
      priority: priority,
    );
  }
}
