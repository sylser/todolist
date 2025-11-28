import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tray_service.dart';

class SettingsScreen extends StatefulWidget {
  final double currentOpacity;
  final bool currentIgnoreMouseEvents;

  const SettingsScreen({
    super.key,
    required this.currentOpacity,
    required this.currentIgnoreMouseEvents,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _opacity;
  late bool _ignoreMouseEvents;

  @override
  void initState() {
    super.initState();
    _opacity = widget.currentOpacity;
    _ignoreMouseEvents = widget.currentIgnoreMouseEvents;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('window_opacity', _opacity);
    await prefs.setBool('ignore_mouse_events', _ignoreMouseEvents);
    
    await windowManager.setOpacity(_opacity);
    await windowManager.setIgnoreMouseEvents(_ignoreMouseEvents);
    
    // 刷新托盘菜单，更新点击穿透状态显示
    await TrayService.refreshMenu();
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '设置',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              '窗口透明度: ${(_opacity * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _opacity,
              min: 0.3,
              max: 1.0,
              divisions: 14,
              label: '${(_opacity * 100).toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() {
                  _opacity = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('点击穿透'),
              subtitle: const Text('启用后窗口不响应鼠标点击，不影响其他应用'),
              value: _ignoreMouseEvents,
              onChanged: (value) {
                setState(() {
                  _ignoreMouseEvents = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


