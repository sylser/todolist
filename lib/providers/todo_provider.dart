import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/todo_item.dart';
import '../models/todo_category.dart';

class TodoProvider with ChangeNotifier {
  List<TodoItem> _todos = [];
  List<TodoCategory> _categories = [];
  String _currentCategoryId = 'default';
  String _searchQuery = '';

  static const String _storageKey = 'todos';
  static const String _categoriesKey = 'todo_categories';

  List<TodoItem> get todos => List.unmodifiable(_todos);
  List<TodoCategory> get categories => List.unmodifiable(_categories);
  String get currentCategoryId => _currentCategoryId;
  String get searchQuery => _searchQuery;

  List<TodoItem> get activeTodos {
    final active = _todos.where((todo) {
      final matchesCategory = todo.categoryId == _currentCategoryId;
      final matchesSearch = _searchQuery.isEmpty ||
          todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return !todo.completed && matchesCategory && matchesSearch;
    }).toList();
    // 按优先级排序：紧急 > 一般 > 不紧急 > 待定
    active.sort((a, b) => a.priority.order.compareTo(b.priority.order));
    return active;
  }

  List<TodoItem> get completedTodos {
    return _todos.where((todo) {
      final matchesCategory = todo.categoryId == _currentCategoryId;
      final matchesSearch = _searchQuery.isEmpty ||
          todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return todo.completed && matchesCategory && matchesSearch;
    }).toList();
  }

  TodoProvider() {
    _loadCategories();
    _loadTodos();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? categoriesJson = prefs.getString(_categoriesKey);
      if (categoriesJson != null) {
        final List<dynamic> decoded = json.decode(categoriesJson);
        _categories =
            decoded.map((item) => TodoCategory.fromJson(item)).toList();
      } else {
        // 初始化默认分类
        _categories = [
          TodoCategory(
            id: 'default',
            name: '工作',
            order: 0,
          ),
          TodoCategory(
            id: 'life',
            name: '生活',
            order: 1,
          ),
        ];
        await _saveCategories();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // 初始化默认分类
      _categories = [
        TodoCategory(
          id: 'default',
          name: '工作',
          order: 0,
        ),
        TodoCategory(
          id: 'life',
          name: '生活',
          order: 1,
        ),
      ];
      await _saveCategories();
    }
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

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(
        _categories.map((category) => category.toJson()).toList(),
      );
      await prefs.setString(_categoriesKey, encoded);
    } catch (e) {
      debugPrint('Error saving categories: $e');
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

  Future<void> addTodo(String title, {String? note}) async {
    if (title.trim().isEmpty) return;

    final todo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      createdAt: DateTime.now(),
      categoryId: _currentCategoryId,
      note: note?.trim() ?? '',
    );

    _todos.insert(0, todo);
    notifyListeners();
    await _saveTodos();
  }

  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final currentTodo = _todos[index];
      final newCompleted = !currentTodo.completed;

      _todos[index] = currentTodo.copyWith(
        completed: newCompleted,
        completedAt: newCompleted ? DateTime.now() : null,
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

  Future<void> updateNote(String id, String note) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(note: note.trim());
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

  // 分类管理方法
  Future<void> setCurrentCategory(String categoryId) async {
    if (_categories.any((cat) => cat.id == categoryId)) {
      _currentCategoryId = categoryId;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    if (name.trim().isEmpty) return;

    final newCategory = TodoCategory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      order: _categories.length,
    );

    _categories.add(newCategory);
    notifyListeners();
    await _saveCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    // 不允许删除默认分类
    if (categoryId == 'default') return;

    // 如果删除的是当前选中的分类，切换到默认分类
    if (categoryId == _currentCategoryId) {
      _currentCategoryId = 'default';
    }

    _categories.removeWhere((cat) => cat.id == categoryId);
    // 将该分类下的所有待办事项移动到默认分类
    for (int i = 0; i < _todos.length; i++) {
      if (_todos[i].categoryId == categoryId) {
        _todos[i] = _todos[i].copyWith(categoryId: 'default');
      }
    }
    notifyListeners();
    await _saveCategories();
    await _saveTodos();
  }

  Future<void> updateCategory(String categoryId, String newName) async {
    if (newName.trim().isEmpty) return;

    final index = _categories.indexWhere((cat) => cat.id == categoryId);
    if (index != -1) {
      _categories[index] = _categories[index].copyWith(name: newName.trim());
      notifyListeners();
      await _saveCategories();
    }
  }

  // 数据导入导出方法
  Future<Map<String, dynamic>> exportData() async {
    return {
      'todos': _todos.map((todo) => todo.toJson()).toList(),
      'categories': _categories.map((category) => category.toJson()).toList(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('categories')) {
        _categories = (data['categories'] as List<dynamic>)
            .map((item) => TodoCategory.fromJson(item))
            .toList();
        await _saveCategories();
      }

      if (data.containsKey('todos')) {
        _todos = (data['todos'] as List<dynamic>)
            .map((item) => TodoItem.fromJson(item))
            .toList();
        await _saveTodos();
      }

      // 确保当前分类存在
      if (!_categories.any((cat) => cat.id == _currentCategoryId)) {
        _currentCategoryId =
            _categories.isNotEmpty ? _categories[0].id : 'default';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  Future<void> clearData() async {
    _todos = [];
    _categories = [
      TodoCategory(
        id: 'default',
        name: '工作',
        order: 0,
      ),
      TodoCategory(
        id: 'life',
        name: '生活',
        order: 1,
      ),
    ];
    _currentCategoryId = 'default';

    notifyListeners();
    await _saveTodos();
    await _saveCategories();
  }

  /// 重新加载数据（用于导入数据后更新UI）
  Future<void> reloadData() async {
    await _loadCategories();
    await _loadTodos();
    notifyListeners();
  }
}
