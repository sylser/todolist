# 项目设置说明

## 快速开始

1. **安装 Flutter SDK**
   - 确保安装 Flutter 3.0.0 或更高版本
   - 运行 `flutter doctor` 检查环境

2. **启用 Windows 桌面支持**
   ```bash
   flutter config --enable-windows-desktop
   ```

3. **获取依赖**
   ```bash
   flutter pub get
   ```

4. **运行应用**
   ```bash
   flutter run -d windows
   ```

## 功能说明

### 基本功能
- ✅ 添加、编辑、删除待办事项
- ✅ 标记任务为完成/未完成
- ✅ 自动记录创建时间
- ✅ 数据自动保存到本地

### 窗口管理功能
- ✅ **置顶窗口**：窗口始终显示在最上层
- ✅ **最小化到右上角**：点击最小化按钮后，窗口缩小为 50x50 的圆形图标
- ✅ **半透明效果**：最小化时窗口透明度降低到 30%
- ✅ **点击穿透**：最小化时窗口不影响其他应用（通过设置小窗口和透明实现）
- ✅ **鼠标激活**：
  - 方案1：鼠标移动到屏幕右侧边缘（需要平台通道支持）
  - 方案2：鼠标悬停在最小化的窗口图标上（已实现）

## 平台通道配置（可选）

如果要启用精确的鼠标边缘检测功能，需要编译 Windows 原生代码：

1. 项目已包含 `mouse_channel.h` 和 `mouse_channel.cpp`
2. 需要在 `windows/runner/CMakeLists.txt` 中添加这些文件
3. 或者在 `windows/runner/main.cpp` 中调用 `SetupMouseChannel`

如果平台通道未配置，应用仍可通过鼠标悬停窗口图标来激活，功能正常使用。

## 构建发布版本

```bash
flutter build windows --release
```

构建产物位于 `build\windows\x64\runner\Release\`

## 注意事项

- Windows 10/11 系统支持最佳
- 首次运行可能需要较长时间编译
- 确保系统已安装 Visual C++ 运行库




