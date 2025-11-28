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
  final DateTime? completedAt;
  final Priority priority;
  final String categoryId;

  TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.completed = false,
    this.completedAt,
    this.priority = Priority.normal,
    this.categoryId = 'default',
  });

  TodoItem copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    bool? completed,
    DateTime? completedAt,
    Priority? priority,
    String? categoryId,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority.name,
      'categoryId': categoryId,
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
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      priority: priority,
      categoryId: json['categoryId'] ?? 'default',
    );
  }
}
