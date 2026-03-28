# ScreenMarker Pro

一款面向演示、录屏和远程讲解场景的macOS辅助工具，支持**屏幕标注**、**按键回显(Keycasting)**和**多项演示参数自定义**。

![Version](https://img.shields.io/badge/version-1.1.3-blue)
![Platform](https://img.shields.io/badge/platform-macOS%2012.0%2B-lightgrey)
![License](https://img.shields.io/badge/license-未定-red)

## ✨ 功能特点

- 🖍️**屏幕标注**：按住已配置修饰键+鼠标右键拖拽，快速高亮屏幕区域
- ⌨️**按键回显**：实时显示快捷键操作，适合录屏、直播和教学讲解
- ⚙️**高度可配置**：支持触发键、颜色模式、线型、线宽、圆角、停留时间、按键回显位置与样式调整
- 🖥️**多显示器支持**：自动覆盖所有显示器，适合复杂演示环境
- ⚡**实时响应**：拖拽时即时绘制，结束后自动淡出
- 🚫**低干扰设计**：菜单栏常驻、点击穿透，不影响当前工作流

## 📸 演示效果

建议直接运行应用体验实际效果。

## 🚀 快速开始

### 安装要求

- macOS 12.0+
- Xcode 15.0+（仅开发）
- 辅助功能权限

### 运行项目

1. 打开项目

```bash
open ScreenMarkerPro.xcodeproj
```

2. 配置开发团队
- 在Xcode中选择项目→Targets→Signing & Capabilities
- 选择你的Apple开发者账号

3. 运行应用（`Cmd + R`）
- 首次运行会请求辅助功能权限
- 点击“打开系统设置”并勾选应用权限
- 应用会自动检测权限并启动

## 🧭 使用方法

1. 查看菜单栏  
应用运行后会在菜单栏显示图标。

2. 绘制标记
- 按住偏好设置中已勾选的修饰键
- 按下鼠标右键并拖拽
- 松开右键后，标记框会短暂停留并自动淡出

3. 使用按键回显
- 在偏好设置中开启按键回显
- 只有“已勾选监听修饰键+另一个按键”组成的快捷键才会触发显示

4. 打开偏好设置
- 点击菜单栏图标→`偏好设置...`

5. 退出应用
- 点击菜单栏图标→`退出`

## ⚙️ 可配置项

### 标记设置

- 绘制触发键可多选配置：`⌘Command`、`⌃Control`、`⌥Option`、`⇧Shift`
- 颜色模式支持：
  - 随机渐变
  - 单色固定
- 线段样式支持：
  - 实线
  - 虚线
- 可调参数：
  - 边框粗细
  - 圆角大小
  - 标记停留时间

### 按键回显设置

- 可单独开启或关闭按键回显
- 可配置监听修饰键
- 仅当“已勾选修饰键+另一个按键”组成快捷键时才触发回显
- 可配置显示位置：
  - 左上角
  - 右上角
  - 左下角
  - 右下角
  - 中间顶部
  - 中间底部
- 可配置样式：
  - 背景颜色
  - 文字颜色
  - 边框颜色
  - 字体大小
  - 停留时间
  - 连按聚合时间窗口

### 内置渐变主题

- `laserBlue`：激光蓝→霓虹紫
- `neonGreen`：霓虹绿→天蓝
- `hotPink`：热粉→橙红

## 📦 发布

仓库已经补充了本地打包脚本和GitHub Release工作流模板：

- 本地打包与GitHub发布说明见[docs/发布到GitHub与Release.md](docs/发布到GitHub与Release.md)
- 签名与公证说明见[签名与公证指南.md](签名与公证指南.md)

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

- **远程会议**：在屏幕共享时突出重点
- **教学演示**：引导学员关注特定区域
- **产品展示**：强调功能或界面元素
- **代码Review**：标记需要讨论的代码块
- **录屏教程**：通过按键回显展示实际操作路径

## 🛠️ 技术架构

### 核心模块

```text
ScreenMarkerPro/
├── AppDelegate.swift              # 应用入口
├── MenuBarManager.swift           # 菜单栏管理
├── SettingsManager.swift          # 偏好设置与持久化
├── AccessibilityManager.swift     # 权限管理
├── EventMonitor.swift             # 全局事件监听
├── OverlayWindow.swift            # 屏幕标注覆盖窗口
├── DrawingManager.swift           # 标记框绘制与生命周期管理
├── GradientRectView.swift         # 标记框视图
├── KeyCastManager.swift           # 按键回显逻辑
├── KeyCastWindow.swift            # 按键回显窗口
└── KeyCastView.swift              # 按键回显界面
```

### 关键技术

- **窗口层级**：`.screenSaver`，确保显示在所有应用之上
- **事件监听**：`CGEvent.tap`，监听鼠标和键盘全局事件
- **坐标转换**：智能处理多屏幕坐标系和屏幕切换
- **动画系统**：`CAAnimation` + EaseInEaseOut淡出效果
- **生命周期管理**：`DispatchWorkItem`管理标记框自动消失
- **SwiftUI + AppKit混合UI**：用于偏好设置和按键回显界面

## 🐛 已知问题

- macOS 12上开机启动能力受限（需使用旧API）
- 某些全屏应用场景下，覆盖层显示可能受到系统窗口策略影响
- 未签名、未公证版本在首次打开时会触发系统安全提示

## 🤝 贡献

欢迎提交Issue和PR。

## 📄 许可证

未定
