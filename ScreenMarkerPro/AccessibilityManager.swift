//
//  AccessibilityManager.swift
//  ScreenMarkerPro
//
//  Created on 2026-02-05.
//

import Cocoa

/// 辅助功能权限管理器
class AccessibilityManager {
    
    static let shared = AccessibilityManager()
    
    private init() {}
    
    /// 检查是否已授予辅助功能权限
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// 请求辅助功能权限（会显示系统弹窗）
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// 打开系统设置中的隐私与安全 - 辅助功能页面
    func openSystemPreferences() {
        // macOS 13+ 使用新的系统设置URL scheme
        if #available(macOS 13.0, *) {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // macOS 12 使用旧的偏好设置
            let script = """
            tell application "System Preferences"
                activate
                set current pane to pane "com.apple.preference.security"
                reveal anchor "Privacy_Accessibility" of pane "com.apple.preference.security"
            end tell
            """
            
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                
                if let error = error {
                    print("打开系统设置失败: \(error)")
                }
            }
        }
    }
    
    /// 显示权限请求对话框
    func showPermissionAlert(completion: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "ScreenMarker Pro需要辅助功能权限来监听键盘和鼠标事件。\n\n请在打开的系统设置中，勾选「ScreenMarker Pro」旁边的复选框。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            openSystemPreferences()
            completion(true)
        } else {
            completion(false)
        }
    }
}
