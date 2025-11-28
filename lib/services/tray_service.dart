import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

class TrayService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await trayManager.setIcon('assets/icon.ico');
    } catch (e) {
      // 图标文件不存在时继续，不影响功能
      debugPrint('托盘图标加载失败: $e');
    }

    await _updateMenu();
    _initialized = true;
  }

  // 更新托盘菜单
  static Future<void> _updateMenu() async {
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'open',
          label: '打开',
        ),
        MenuItem(
          key: 'settings',
          label: '设置',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'export_data',
          label: '导出数据',
        ),
        MenuItem(
          key: 'import_data',
          label: '导入数据',
        ),
        MenuItem(
          key: 'clear_data',
          label: '清空数据',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: '退出',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  // 刷新菜单显示（在状态改变后调用）
  static Future<void> refreshMenu() async {
    await _updateMenu();
  }

  static Future<void> handleTrayAction(String menuItemKey) async {
    switch (menuItemKey) {
      case 'open':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'settings':
        // 设置窗口会通过回调处理
        break;
      case 'export_data':
        await _exportData();
        break;
      case 'import_data':
        // import_data 现在由 main.dart 中的 onTrayMenuItemClick 处理
        // 这里不需要处理，但保留 case 以避免错误
        break;
      case 'clear_data':
        // clear_data 现在由 main.dart 中的 onTrayMenuItemClick 处理
        // 这里不需要处理，但保留 case 以避免错误
        break;
      case 'exit':
        await windowManager.destroy();
        break;
    }
  }

  // 导出数据到程序当前目录，使用JSON格式
  static Future<void> _exportData() async {
    try {
      // 获取程序当前目录
      String currentDir = '';
      if (Platform.isWindows) {
        // Windows 下获取可执行文件所在目录
        currentDir = path.dirname(Platform.resolvedExecutable);
      } else if (Platform.isMacOS || Platform.isLinux) {
        // macOS/Linux 下获取可执行文件所在目录
        currentDir = path.dirname(Platform.resolvedExecutable);
      }

      // 创建文件路径
      final dateFormat =
          DateTime.now().toString().replaceAll(RegExp(r'[\/:*?"<>| ]'), '-');
      final filePath =
          path.join(currentDir, 'todolist_export_$dateFormat.json');

      // 获取数据
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getString('todos') ?? '[]';
      final categoriesJson = prefs.getString('todo_categories') ?? '[]';

      // 构建导出数据
      final exportData = {
        'todos': json.decode(todosJson),
        'categories': json.decode(categoriesJson),
        'exportDate': DateTime.now().toIso8601String(),
      };

      // 写入文件
      final file = File(filePath);
      final encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(exportData));

      debugPrint('数据已导出到: $filePath');
      
      // 自动打开文件所在文件夹
      try {
        if (Platform.isWindows) {
          // Windows: 使用 explorer 打开文件夹并选中文件
          await Process.run('explorer', ['/select,', filePath]);
        } else if (Platform.isMacOS) {
          // macOS: 使用 open 命令打开文件夹并选中文件
          await Process.run('open', ['-R', filePath]);
        } else if (Platform.isLinux) {
          // Linux: 使用文件管理器打开文件夹
          await Process.run('xdg-open', [currentDir]);
        }
      } catch (e) {
        debugPrint('打开文件夹失败: $e');
      }
    } catch (e) {
      debugPrint('导出数据失败: $e');
    }
  }

  // 导入数据：弹出文件选择对话框
  static Future<void> importData() async {
    try {
      // 获取程序所在目录作为默认路径
      String initialDirectory = '';
      if (Platform.isWindows) {
        initialDirectory = path.dirname(Platform.resolvedExecutable);
      } else if (Platform.isMacOS || Platform.isLinux) {
        initialDirectory = path.dirname(Platform.resolvedExecutable);
      }

      // 弹出文件选择对话框
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: initialDirectory.isNotEmpty ? initialDirectory : null,
        dialogTitle: '选择要导入的数据文件',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        // 读取文件内容
        final content = await file.readAsString();
        final importData = json.decode(content);

        // 验证数据格式
        if (!importData.containsKey('todos') || !importData.containsKey('categories')) {
          debugPrint('导入文件格式不正确');
          return;
        }

        // 保存数据
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('todos', json.encode(importData['todos'] ?? []));
        await prefs.setString(
            'todo_categories', json.encode(importData['categories'] ?? []));

        debugPrint('数据已从 $filePath 导入');
      } else {
        debugPrint('用户取消了文件选择');
      }
    } catch (e) {
      debugPrint('导入数据失败: $e');
    }
  }

  // 清空所有数据（仅清空存储，UI更新由调用方处理）
  static Future<void> clearData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('todos');
      await prefs.remove('todo_categories');
      debugPrint('数据已清空');
    } catch (e) {
      debugPrint('清空数据失败: $e');
    }
  }

  // 清空所有数据（内部方法，已废弃，使用 clearData 代替）
  static Future<void> _clearData() async {
    await clearData();
  }
}
