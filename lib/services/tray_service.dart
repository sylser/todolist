import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 更新托盘菜单，读取当前点击穿透状态
  static Future<void> _updateMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final ignoreMouseEvents = prefs.getBool('ignore_mouse_events') ?? false;
    
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'open',
          label: '打开',
        ),
        MenuItem(
          key: 'click_through',
          label: ignoreMouseEvents ? '点击穿透: ✓' : '点击穿透',
        ),
        MenuItem(
          key: 'settings',
          label: '设置',
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
      case 'click_through':
        // 切换点击穿透状态
        final prefs = await SharedPreferences.getInstance();
        final currentState = prefs.getBool('ignore_mouse_events') ?? false;
        final newState = !currentState;
        
        await prefs.setBool('ignore_mouse_events', newState);
        await windowManager.setIgnoreMouseEvents(newState);
        
        // 刷新菜单显示新状态
        await refreshMenu();
        break;
      case 'settings':
        // 设置窗口会通过回调处理
        break;
      case 'exit':
        await windowManager.destroy();
        break;
    }
  }
}

