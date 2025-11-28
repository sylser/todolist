import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              _buildHeader(context),
              _buildCategoryTabs(provider),
              Expanded(
                child: _buildTodoList(provider),
              ),
              _buildInputField(context, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.checklist, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) async {
                // 开始拖拽窗口
                await windowManager.startDragging();
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                child: const Text(
                  '待办事项',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
            tooltip: '关闭到系统托盘',
            onPressed: () async {
              // 隐藏窗口到系统托盘
              await windowManager.hide();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(TodoProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...provider.categories.map((category) {
              final isSelected = provider.currentCategoryId == category.id;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: InkWell(
                  onTap: () {
                    provider.setCurrentCategory(category.id);
                  },
                  onLongPress: () {
                    if (category.id != 'default') {
                      _showCategoryMenu(provider, category.id, category.name);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (category.id != 'default' && isSelected)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            color: Colors.white,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              provider.deleteCategory(category.id);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            IconButton(
              icon: const Icon(Icons.add),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                _showAddCategoryDialog(provider);
              },
              tooltip: '添加分类',
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryMenu(
      TodoProvider provider, String categoryId, String categoryName) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 100, 0, 0),
      items: [
        PopupMenuItem(
          child: const Text('重命名'),
          onTap: () {
            _showRenameCategoryDialog(provider, categoryId, categoryName);
          },
        ),
        PopupMenuItem(
          child: const Text('删除'),
          onTap: () {
            provider.deleteCategory(categoryId);
          },
        ),
      ],
    );
  }

  void _showAddCategoryDialog(TodoProvider provider) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加分类'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '分类名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addCategory(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(
      TodoProvider provider, String categoryId, String currentName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名分类'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '新分类名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.updateCategory(categoryId, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList(TodoProvider provider) {
    final activeTodos = provider.activeTodos;
    final completedTodos = provider.completedTodos;

    if (activeTodos.isEmpty && completedTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无待办事项',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: activeTodos.length +
          (completedTodos.isNotEmpty ? 1 : 0) +
          completedTodos.length,
      itemBuilder: (context, index) {
        if (index < activeTodos.length) {
          return TodoItemWidget(todo: activeTodos[index]);
        }

        if (index == activeTodos.length && completedTodos.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              '已完成 (${completedTodos.length})',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final completedIndex = index - activeTodos.length - 1;
        return TodoItemWidget(todo: completedTodos[completedIndex]);
      },
    );
  }

  Widget _buildInputField(BuildContext context, TodoProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '输入待办事项...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                    Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  provider.addTodo(value);
                  _textController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                provider.addTodo(_textController.text);
                _textController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
