import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/overlay_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final overlayProvider = Provider.of<OverlayProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
                '悬浮待办面板',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildOpacitySlider(context, overlayProvider),
              const SizedBox(height: 12),
              _buildAnchorSelector(overlayProvider),
              const SizedBox(height: 12),
              _buildOverlayHint(context),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(
                      overlayProvider.isOverlayVisible
                          ? Icons.close_fullscreen
                          : Icons.open_in_new,
                    ),
                    label: Text(
                      overlayProvider.isOverlayVisible ? '关闭浮窗' : '开启浮窗',
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (overlayProvider.isOverlayVisible) {
                        await overlayProvider.hideOverlay();
                      } else {
                        await overlayProvider.showOverlay();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpacitySlider(
      BuildContext context, OverlayProvider overlayProvider) {
    final opacityPercent = (overlayProvider.overlayOpacity * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('背景透明度'),
            Text('$opacityPercent%'),
          ],
        ),
        Slider(
          min: 0.2,
          max: 0.95,
          divisions: 15,
          value: overlayProvider.overlayOpacity,
          onChanged: (value) => overlayProvider.setOpacity(value),
        ),
      ],
    );
  }

  Widget _buildAnchorSelector(OverlayProvider overlayProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('浮窗位置'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: OverlayAnchor.values.map((anchor) {
            final selected = overlayProvider.anchor == anchor;
            return ChoiceChip(
              label: Text(anchor.label),
              selected: selected,
              onSelected: (value) {
                if (value) {
                  overlayProvider.setAnchor(anchor);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOverlayHint(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '点击“开启浮窗”后，窗口会自动固定在指定的屏幕角落并保持置顶，'
        '鼠标点击会穿透到其他软件。\n如需恢复主界面，可按 Esc 或在托盘中选择“打开”。',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
