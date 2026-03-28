# ScreenMarker Pro

极简macOS演示辅助工具，通过`Command + 右键拖拽`在屏幕最顶层绘制彩色渐变矩形框。

![Version](https://img.shields.io/badge/version-1.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS%2012.0%2B-lightgrey)
![License](https://img.shields.io/badge/license-未定-red)

## ✨ 功能特点

- 🎨 **激光蓝→霓虹紫渐变边框** - 视觉吸引力强
- ⌨️ **Command + 右键拖拽** - 简单直观的操作
- 🖥️ **多屏幕完美支持** - 自动覆盖所有显示器
- ⚡ **实时绘制** - 拖拽时即时显示矩形框
- 🎬 **自动消失** - 1.5秒展示+0.5秒淡出动画
- 🚫 **不干扰工作** - 点击穿透，不影响其他应用

## 📸 演示效果

（建议运行后自行体验）

## 🚀 快速开始

### 安装要求

- macOS 12.0+
- Xcode 15.0+（仅开发）
- 辅助功能权限

### 运行项目

1. **打开项目**

   ```bash
   open ScreenMarkerPro.xcodeproj
   ```

2. **配置开发团队**
   - 在Xcode中选择项目 → Targets → Signing & Capabilities
   - 选择您的Apple开发者账号

3. **运行应用** （`Cmd + R`）
   - 首次运行会请求辅助功能权限
   - 点击"打开系统设置"并勾选应用权限
   - 应用会自动检测权限并启动

### 使用方法

1. **查看菜单栏** - 应用运行后会在菜单栏显示图标 📐
2. **绘制标记**：
   - 按住 `Command (⌘)` 键
   - 按下鼠标右键并拖拽
   - 松开右键，矩形定格
   - 1.5秒后自动淡出消失
3. **退出应用** - 点击菜单栏图标 → 退出

## 📦 发布

仓库已经补充了本地打包脚本和GitHub Release工作流模板：

- 本地打包与GitHub发布说明见[docs/发布到GitHub与Release.md](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/docs/发布到GitHub与Release.md)
- 签名与公证说明见[签名与公证指南.md](/Users/mpp/Documents/AI%20Coding/屏幕标注助手/签名与公证指南.md)

常用命令：

```bash
# 无签名打包
bash scripts/package-release.sh --unsigned

# 签名并生成pkg
bash scripts/package-release.sh --signed --with-pkg

# 对已签名产物做公证
bash scripts/notarize-release.sh
```

## 🎯 使用场景

- **远程会议** - 在屏幕共享时突出重点
- **教学演示** - 引导学员关注特定区域
- **产品展示** - 强调功能或界面元素
- **代码Review** - 标记需要讨论的代码块

## 🛠️ 技术架构

### 核心模块

```
ScreenMarkerPro/
├── AppDelegate.swift              # 应用入口
├── MenuBarManager.swift           # 菜单栏管理
├── AccessibilityManager.swift     # 权限管理
├── EventMonitor.swift             # 事件监听（CGEvent.tap）
├── OverlayWindow.swift            # 全屏透明窗口
├── DrawingManager.swift           # 绘制管理
└── GradientRectView.swift         # 渐变矩形视图
```

### 关键技术

- **窗口层级**: `.screenSaver` - 确保在所有应用之上
- **事件监听**: `CGEvent.tap` - 拦截系统右键菜单
- **坐标转换**: 智能处理多屏幕坐标系转换
- **动画系统**: `CAAnimation` + EaseInEaseOut 缓动
- **计时器管理**: `DispatchWorkItem` 字典管理每个矩形生命周期

## ⚙️ 高级配置

### 自定义渐变色

在`GradientRectView.swift`中已预留3种渐变主题：

- `laserBlue` - 激光蓝→霓虹紫（默认）
- `neonGreen` - 霓虹绿→天蓝
- `hotPink` - 热粉→橙红

修改第48行`gradientStyle`属性即可切换。

### 调整展示时长

在`DrawingManager.swift`中修改：

```swift
private let displayDuration: TimeInterval = 1.5  // 展示时长
private let fadeDuration: TimeInterval = 0.5     // 淡出时长
```

## 📋 开发进度

- [x] **第一阶段：MVP原型**
- [x] **第二阶段：事件驱动**
- [x] **第三阶段：动画与美化**
- [x] **第四阶段：发布准备**

详见项目文档和各阶段总结。

## 🐛 已知问题

- macOS 12上开机启动功能受限（需使用旧API）
- 在某些全屏应用中可能需要退出全屏才能看到覆盖窗口（极少数情况）

## 🤝 贡献

欢迎提交Issue和PR！

## 📄 许可证

未定

---

**Made with ❤️ for better presentations**
