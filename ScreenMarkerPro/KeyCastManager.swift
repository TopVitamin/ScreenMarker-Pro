import Foundation
import Combine
import Carbon
import Cocoa
import SwiftUI

struct KeyCastItem: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    var count: Int
    let timestamp: TimeInterval
    
    // 显示文本：只显示符号，计数由View层处理
    var displayText: String {
        return symbol
    }
}

class KeyCastManager: ObservableObject {
    static let shared = KeyCastManager()
    
    @Published var keys: [KeyCastItem] = []
    
    // 回调：当有新按键被添加时触发
    var onKeyEvent: (() -> Void)?
    
    private var lastKeyTime: TimeInterval = 0
    private var groupTimeThreshold: TimeInterval {
        // 对设置值做边界保护，避免异常值影响聚合逻辑
        min(max(SettingsManager.shared.keyCastGroupTimeWindow, 0.2), 5.0)
    }
    private let verboseLogEnabled = false
    private var cleanupTimer: Timer?
    private let textInputRoles: Set<String> = ["AXTextField", "AXTextArea", "AXComboBox", "AXSearchField"]
    
    private init() {
        startCleanupTimer()
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    /// 核心入口：处理按键事件
    func handleKeyEvent(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        log("KeyCastManager: Handling key code: \(keyCode), modifiers: \(modifiers)")
        
        // 安全输入检测：如果系统处于安全输入模式（如输入密码），则不记录
        if isSecureInputEnabled() {
            log("KeyCastManager: Secure Input is ENABLED. Ignoring event.")
            return
        }
        
        // 过滤逻辑
        let isModifierOnly = isModifierKeyCode(keyCode)
        let activeModifiers = modifiers.intersection([.command, .control, .option, .shift])
        let monitoredModifiers = SettingsManager.shared.keyCastTriggerModifiers
        let hasConfiguredModifier = !activeModifiers.intersection(monitoredModifiers).isEmpty
        
        // 只记录快捷键：必须包含至少一个被勾选的修饰键
        if !hasConfiguredModifier {
            return
        }
        
        // 忽略纯修饰键按下的瞬间，确保至少是“修饰键+另一个按键”
        if isModifierOnly {
             // print("Ignored purely modifier key press")
             return 
        }

        // 隐私增强：在文本输入场景下，过滤可能构成正文/密码字符的Shift单修饰输入
        if shouldBlockForPrivacy(keyCode: keyCode, modifiers: modifiers) {
            log("KeyCastManager: Privacy guard blocked key event.")
            return
        }
        
        // 构建显示字符串
        var symbol = ""
        
        // 1. 添加修饰键前缀
        var modString = ""
        if modifiers.contains(.control) { symbol += "⌃ "; modString += "Ctrl " }
        if modifiers.contains(.option) { symbol += "⌥ "; modString += "Opt " }
        if modifiers.contains(.shift) { symbol += "⇧ "; modString += "Shift " }
        if modifiers.contains(.command) { symbol += "⌘ "; modString += "Cmd " }
        
        log("KeyCastManager: Modifiers parsed: \(modString)")
        
        // 2. 添加主按键
        guard let keyStr = KeyCodeMapper.shared.map(keyCode: keyCode) else {
            log("KeyCastManager: Could not map key code: \(keyCode)")
            return
        }
        symbol += keyStr
        log("KeyCastManager: Symbol constructed: [\(symbol)]")
        
        // 防御：避免空白文本进入UI导致仅显示背景框
        let visibleSymbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        if visibleSymbol.isEmpty {
            let codePoints = symbol.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: ",")
            log("KeyCastManager: Ignored blank symbol, scalars: [\(codePoints)]")
            return
        }
        
        let now = Date().timeIntervalSince1970
        
        // 聚合逻辑
        // 如果列表不为空，且最后一个按键和当前按键相同，且时间间隔在阈值内
        if let last = keys.last, last.symbol == symbol, (now - lastKeyTime) < groupTimeThreshold {
            // 更新最后一个Item的计数
            updateLastKeyCount()
        } else {
            addKey(symbol: symbol, timestamp: now)
        }
        
        log("KeyCastManager: ✅ KEY ACCEPTED -> \(symbol)")
        lastKeyTime = now
    }
    
    private func addKey(symbol: String, timestamp: TimeInterval) {
        performOnMain {
            self.log("KeyCastManager: Adding to UI keys queue. Current count: \(self.keys.count)")
            // 限制最大堆叠数，例如3
            if self.keys.count >= 3 {
                self.keys.removeFirst()
            }
            let newItem = KeyCastItem(symbol: symbol, count: 1, timestamp: timestamp)
            self.keys.append(newItem)
            
            // 触发回调：保证在keys更新之后执行，避免首帧时序竞争
            self.onKeyEvent?()
        }
    }
    
    private func updateLastKeyCount() {
        performOnMain {
            guard var last = self.keys.last else { return }
            last.count += 1
            self.keys[self.keys.count - 1] = last
            
            // 触发回调
            self.onKeyEvent?()
        }
    }
    
    private func startCleanupTimer() {
        // 定期清理过期的按键显示 (例如5秒后淡出)
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.cleanupKeys()
        }
    }
    
    private func cleanupKeys() {
        let now = Date().timeIntervalSince1970
        let threshold = SettingsManager.shared.keyCastDuration
        
        performOnMain {
            if let first = self.keys.first, (now - first.timestamp) > threshold {
                _ = withAnimation(.easeOut) {
                    self.keys.removeFirst()
                }
            }
        }
    }
    
    // MARK: - Helper
    
    private func isModifierKeyCode(_ keyCode: UInt16) -> Bool {
        return keyCode == kVK_Command || keyCode == kVK_Shift || keyCode == kVK_CapsLock || keyCode == kVK_Option || keyCode == kVK_Control || keyCode == kVK_RightShift || keyCode == kVK_RightCommand || keyCode == kVK_RightOption || keyCode == kVK_RightControl
    }
    
    /// 检测是否处于安全输入模式（例如密码输入框）
    private func isSecureInputEnabled() -> Bool {
        // IsSecureEventInputEnabled 是 Carbon 的 API
        return IsSecureEventInputEnabled()
    }

    /// 隐私增强策略：
    /// 1) 保留Shift触发能力；
    /// 2) 但在文本输入场景下，Shift单修饰+可打印字符不回显，避免捕获正文/口令内容。
    private func shouldBlockForPrivacy(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> Bool {
        let hasStrongModifiers = !modifiers.intersection([.command, .control, .option]).isEmpty
        let isShiftOnly = modifiers.contains(.shift) && !hasStrongModifiers

        guard isShiftOnly else { return false }
        guard isPotentiallySensitivePrintableKey(keyCode) else { return false }

        let context = focusedInputContext()
        return context.isTextInput || context.isSecureTextInput
    }

    private func isPotentiallySensitivePrintableKey(_ keyCode: UInt16) -> Bool {
        guard let keyStr = KeyCodeMapper.shared.map(keyCode: keyCode) else { return false }
        let trimmed = keyStr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 1, let scalar = trimmed.unicodeScalars.first else { return false }

        let printableSet = CharacterSet.alphanumerics.union(.punctuationCharacters)
        return printableSet.contains(scalar)
    }

    private func focusedInputContext() -> (isTextInput: Bool, isSecureTextInput: Bool) {
        guard AXIsProcessTrusted() else {
            return (false, false)
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard result == .success, let focusedValue else {
            return (false, false)
        }

        guard CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else {
            return (false, false)
        }

        let focusedElement = focusedValue as! AXUIElement
        let role = axStringAttribute(of: focusedElement, attribute: kAXRoleAttribute as String)
        let subrole = axStringAttribute(of: focusedElement, attribute: kAXSubroleAttribute as String)

        let isSecureBySubrole = subrole == "AXSecureTextField"
        let isSecureByAttribute = axBoolAttribute(of: focusedElement, attribute: "AXSecureTextEntry") ?? false
        let isSecureTextInput = isSecureBySubrole || isSecureByAttribute

        let isTextInput = role.map { textInputRoles.contains($0) } ?? false
        return (isTextInput, isSecureTextInput)
    }

    private func axStringAttribute(of element: AXUIElement, attribute: String) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else { return nil }
        return value as? String
    }

    private func axBoolAttribute(of element: AXUIElement, attribute: String) -> Bool? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let value else { return nil }

        if let boolValue = value as? Bool {
            return boolValue
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        return nil
    }

    private func performOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
    
    private func log(_ message: String) {
        guard verboseLogEnabled else { return }
        print(message)
    }
}
