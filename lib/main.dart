import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/todo_item.dart';
import 'providers/todo_provider.dart';
import 'screens/main_screen.dart';
import 'services/tray_service.dart';
import 'screens/settings_screen.dart';

// 全局导航键，用于在托盘菜单回调中显示对话框
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  // 初始化系统托盘图标（如果文件不存在会报错，但不影响应用运行）
  try {
    await trayManager.setIcon('assets/icon.ico');
  } catch (e) {
    debugPrint('无法加载托盘图标: $e');
  }

  // 加载保存的设置
  final prefs = await SharedPreferences.getInstance();
  final opacity = prefs.getDouble('window_opacity') ?? 0.95;
  final ignoreMouseEvents = prefs.getBool('ignore_mouse_events') ?? false;

  WindowOptions windowOptions = const WindowOptions(
    size: Size(350, 500),
    minimumSize: Size(300, 400),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    
    // 设置初始位置到屏幕右上角
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isNotEmpty) {
      final display = views.first;
      final screenWidth = display.physicalSize.width / display.devicePixelRatio;
      await windowManager.setPosition(Offset(screenWidth - 350, 0));
    }
    
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setOpacity(opacity);
    await windowManager.setIgnoreMouseEvents(ignoreMouseEvents);
    await windowManager.setAlwaysOnTop(true);
  });

  // 初始化系统托盘
  await TrayService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    // 左键点击托盘图标时显示窗口
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    // 右键点击显示菜单
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    final key = menuItem.key ?? '';
    
    // 如果是设置菜单，先显示窗口，再显示设置对话框
    if (key == 'settings') {
      await windowManager.show();
      await windowManager.focus();
      
      // 等待窗口显示后再显示对话框
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 使用全局导航键来显示对话框
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null) {
        final prefs = await SharedPreferences.getInstance();
        final opacity = prefs.getDouble('window_opacity') ?? 0.95;
        final ignoreMouseEvents = prefs.getBool('ignore_mouse_events') ?? false;
        
        showDialog(
          context: navigatorContext,
          barrierDismissible: true,
          builder: (context) => SettingsScreen(
            currentOpacity: opacity,
            currentIgnoreMouseEvents: ignoreMouseEvents,
          ),
        );
      }
    } else {
      // 其他菜单项（包括 click_through）由 TrayService 处理
      await TrayService.handleTrayAction(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Todo List',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

