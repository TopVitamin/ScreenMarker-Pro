//
//  MenuBarManager.swift
//  ScreenMarkerPro
//
//  Created on 2026-02-05.
//

import Cocoa
import ServiceManagement
import SwiftUI

/// 菜单栏管理器 - 负责菜单栏图标和菜单
class MenuBarManager: NSObject {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var settingsWindowController: NSWindowController?
    private var permissionItem: NSMenuItem?
    private var usageHintItem: NSMenuItem?
    
    /// 开机启动状态变化回调
    var onLoginItemStatusChanged: ((Bool) -> Void)?
    var onOpenAccessibilitySettings: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        setupStatusItem()
        setupMenu()
    }
    
    // MARK: - Setup
    
    private func setupStatusItem() {
        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // 使用SF Symbols图标
            if let image = NSImage(systemSymbolName: "rectangle.dashed.badge.record", accessibilityDescription: "ScreenMarker Pro") {
                image.isTemplate = true  // 支持深色模式
                button.image = image
            } else {
                // 降级方案：使用文本
                button.title = "📐"
            }
            
            button.toolTip = "ScreenMarker Pro\n按住 \(SettingsManager.shared.drawingHotkeyDisplayText)拖拽绘制标记"
        }
        
        statusItem?.menu = menu
    }
    
    private func setupMenu() {
        menu.removeAllItems()
        
        // 标题项（不可点击）
        let titleItem = NSMenuItem(title: "ScreenMarker Pro", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        // 权限警告（初始隐藏）
        permissionItem = NSMenuItem(
            title: "⚠️ 授予辅助权限...",
            action: #selector(openSystemAccessibility),
            keyEquivalent: ""
        )
        permissionItem?.target = self
        permissionItem?.isHidden = true
        if let permissionItem = permissionItem {
            menu.addItem(permissionItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 偏好设置
        let settingsItem = NSMenuItem(
            title: "偏好设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 使用说明
        let usageItem = NSMenuItem(title: "使用方法：\(SettingsManager.shared.drawingHotkeyDisplayText)拖拽", action: nil, keyEquivalent: "")
        usageItem.isEnabled = false
        menu.addItem(usageItem)
        usageHintItem = usageItem
        
        menu.addItem(NSMenuItem.separator())
        
        // 开机启动
        let loginItem = NSMenuItem(
            title: "开机启动",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = isLoginItemEnabled() ? .on : .off
        menu.addItem(loginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 关于
        let aboutItem = NSMenuItem(
            title: "关于ScreenMarker Pro",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // 退出
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func openSystemAccessibility() {
        AccessibilityManager.shared.openSystemPreferences()
        onOpenAccessibilitySettings?()
    }
    
    @objc private func openSettings() {
        if settingsWindowController == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 620),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "偏好设置"
            window.contentViewController = hostingController
            window.center()
            // 确保窗口在最顶层 (高于OverlayWindow的.screenSaver级别)
            window.level = .screenSaver + 1
            // 确保窗口释放行为
            window.isReleasedWhenClosed = false
            
            settingsWindowController = NSWindowController(window: window)
        }
        
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func toggleLoginItem() {
        let currentState = isLoginItemEnabled()
        
        if #available(macOS 13.0, *) {
            // macOS 13+ 使用新的SMAppService API
            do {
                if currentState {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
                updateLoginItemState()
                onLoginItemStatusChanged?(!currentState)
            } catch {
                showError("设置开机启动失败: \(error.localizedDescription)")
            }
        } else {
            // macOS 12 使用旧的API
            let success = SMLoginItemSetEnabled("com.topvitamin.ScreenMarkerPro" as CFString, !currentState)
            if success {
                updateLoginItemState()
                onLoginItemStatusChanged?(!currentState)
            } else {
                showError("设置开机启动失败")
            }
        }
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "ScreenMarker Pro V1.1.2"
        alert.informativeText = ""
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")

        let contentWidth: CGFloat = 420

        let bodyField = NSTextField(wrappingLabelWithString: """
一款轻量级屏幕标注工具，专为演示场景设计。轻量、快速、不干扰。

你可以用它：
• 按住修饰键+鼠标右键拖拽，快速高亮屏幕区域
• 支持多显示器标注并自动淡出，减少视觉干扰
• 开启按键回显，展示按下的快捷键
• 自定义触发键、样式、显示位置与停留时间

让讲解过程更清晰，观众更容易跟上你的操作节奏。
""")
        bodyField.frame = NSRect(x: 0, y: 32, width: contentWidth, height: 180)
        bodyField.alignment = .left
        bodyField.lineBreakMode = .byWordWrapping
        bodyField.maximumNumberOfLines = 0

        let footerField = NSTextField(labelWithString: "")
        footerField.frame = NSRect(x: 0, y: 0, width: contentWidth, height: 22)
        footerField.allowsEditingTextAttributes = true
        footerField.isSelectable = true
        footerField.isBordered = false
        footerField.drawsBackground = false

        let footerText = "Created by PM维他命 | © 2026 ScreenMarker Pro"
        let attributedFooter = NSMutableAttributedString(string: footerText)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        attributedFooter.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: footerText.count))

        if let range = footerText.range(of: "PM维他命") {
            let nsRange = NSRange(range, in: footerText)
            attributedFooter.addAttribute(.link, value: "https://www.yuque.com/jiaowovitamin", range: nsRange)
            attributedFooter.addAttribute(.foregroundColor, value: NSColor.linkColor, range: nsRange)
            attributedFooter.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
        }
        footerField.attributedStringValue = attributedFooter

        let accessory = NSView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 212))
        accessory.addSubview(bodyField)
        accessory.addSubview(footerField)
        alert.accessoryView = accessory

        _ = alert.runModal()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Helper Methods
    
    private func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // macOS 12 需要通过其他方式检查，这里简化处理
            return false
        }
    }
    
    private func updateLoginItemState() {
        if let loginItem = menu.item(withTitle: "开机启动") {
            loginItem.state = isLoginItemEnabled() ? .on : .off
        }
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "错误"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    /// 更新菜单栏图标提示
    func updateTooltip(_ text: String) {
        statusItem?.button?.toolTip = text
    }

    /// 更新绘制热键提示
    func updateDrawingHotkeyHint(_ hotkeyText: String) {
        usageHintItem?.title = "使用方法：\(hotkeyText)拖拽"
        statusItem?.button?.toolTip = "ScreenMarker Pro\n按住 \(hotkeyText)拖拽绘制标记"
    }
    
    /// 更新权限状态显示
    func updatePermissionStatus(_ hasPermission: Bool) {
        permissionItem?.isHidden = hasPermission
        
        // 如果没有权限，更新图标或提示
        if !hasPermission {
            statusItem?.button?.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "缺少权限")
            statusItem?.button?.image?.isTemplate = true
        } else {
            // 恢复正常图标
            statusItem?.button?.image = NSImage(systemSymbolName: "rectangle.dashed.badge.record", accessibilityDescription: "ScreenMarker Pro")
            statusItem?.button?.image?.isTemplate = true
        }
    }
}
