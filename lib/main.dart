import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'providers/todo_provider.dart';
import 'providers/overlay_provider.dart';
import 'screens/main_screen.dart';
import 'services/tray_service.dart';
import 'services/reminder_service.dart';
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

  WindowOptions windowOptions = const WindowOptions(
    size: Size(420, 620),
    minimumSize: Size(360, 500),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();

    // 先显示窗口
    await windowManager.show();

    // 等待窗口完全显示后再设置位置
    await Future.delayed(const Duration(milliseconds: 50));

    // 设置初始位置到屏幕正中间
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isNotEmpty) {
      final display = views.first;
      final screenWidth = display.physicalSize.width / display.devicePixelRatio;
      final screenHeight =
          display.physicalSize.height / display.devicePixelRatio;
      // 窗口大小为 420x620，计算居中位置（确保在屏幕正中间）
      final centerX = (screenWidth - 420) / 2;
      final centerY = (screenHeight - 620) / 2;
      // 确保位置不为负数
      await windowManager.setPosition(
        Offset(centerX.clamp(0.0, double.infinity),
            centerY.clamp(0.0, double.infinity)),
      );
    }

    await windowManager.focus();
    await windowManager.setOpacity(0.95);
    await windowManager.setIgnoreMouseEvents(false);
    await windowManager.setAlwaysOnTop(true);

    // 延迟一点后重新启用阴影，确保在所有操作完成后阴影仍然存在
    await Future.delayed(const Duration(milliseconds: 100));
    // 通过重新设置窗口属性来确保阴影保持
    await windowManager.setAsFrameless();
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
  OverlayProvider? get _overlayProvider {
    final context = navigatorKey.currentContext;
    if (context == null) return null;
    return Provider.of<OverlayProvider>(context, listen: false);
  }

  Future<void> _restoreNormalWindow() async {
    final overlayProvider = _overlayProvider;
    if (overlayProvider != null) {
      await overlayProvider.hideOverlay();
    }
  }

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    // 停止提醒服务
    ReminderService.stop();
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    // 左键点击托盘图标时显示窗口
    _restoreNormalWindow();
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
      await _restoreNormalWindow();
      await windowManager.show();
      await windowManager.focus();

      // 等待窗口显示后再显示对话框
      await Future.delayed(const Duration(milliseconds: 100));

      // 使用全局导航键来显示对话框
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null) {
        showDialog(
          context: navigatorContext,
          barrierDismissible: true,
          builder: (context) => const SettingsScreen(),
        );
      }
    } else if (key == 'clear_data') {
      // 清空数据：先清空存储，然后通知 Provider 更新
      await TrayService.clearData();

      // 获取 Provider 并调用 clearData 方法以更新 UI
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null) {
        final provider =
            Provider.of<TodoProvider>(navigatorContext, listen: false);
        await provider.clearData();
      }
    } else if (key == 'import_data') {
      // 导入数据：先显示窗口，然后执行导入
      await windowManager.show();
      await windowManager.focus();

      // 等待窗口显示
      await Future.delayed(const Duration(milliseconds: 100));

      // 执行导入
      await TrayService.importData();

      // 获取 Provider 并重新加载数据以更新 UI
      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null) {
        final provider =
            Provider.of<TodoProvider>(navigatorContext, listen: false);
        // 重新加载数据
        await provider.reloadData();
      }
    } else {
      if (key == 'open') {
        await _restoreNormalWindow();
      }
      // 其他菜单项由 TrayService 处理
      await TrayService.handleTrayAction(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OverlayProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = TodoProvider();
            // 启动提醒服务
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ReminderService.start(provider);
            });
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Todo List',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Microsoft YaHei',
        ),
        home: const MainScreen(),
      ),
    );
  }
}
