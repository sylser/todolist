import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/todo_item.dart';

class TodoProvider with ChangeNotifier {
  List<TodoItem> _todos = [];
  static const String _storageKey = 'todos';

  List<TodoItem> get todos => List.unmodifiable(_todos);
  
  List<TodoItem> get activeTodos {
    final active = _todos.where((todo) => !todo.completed).toList();
    // 按优先级排序：紧急 > 一般 > 不紧急 > 待定
    active.sort((a, b) => a.priority.order.compareTo(b.priority.order));
    return active;
  }
  
  List<TodoItem> get completedTodos => _todos.where((todo) => todo.completed).toList();

  TodoProvider() {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosJson = prefs.getString(_storageKey);
      if (todosJson != null) {
        final List<dynamic> decoded = json.decode(todosJson);
        _todos = decoded.map((item) => TodoItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading todos: $e');
    }
  }

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(
        _todos.map((todo) => todo.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving todos: $e');
    }
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return;

    final todo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      createdAt: DateTime.now(),
    );

    _todos.insert(0, todo);
    notifyListeners();
    await _saveTodos();
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        completed: !_todos[index].completed,
      );
      notifyListeners();
      await _saveTodos();
    }
  }

  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
    await _saveTodos();
  }

  Future<void> updateTodo(String id, String newTitle) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1 && newTitle.trim().isNotEmpty) {
      _todos[index] = _todos[index].copyWith(title: newTitle.trim());
      notifyListeners();
      await _saveTodos();
    }
  }

  Future<void> updatePriority(String id, Priority priority) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(priority: priority);
      notifyListeners();
      await _saveTodos();
    }
  }
}


