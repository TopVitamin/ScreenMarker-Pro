//
//  SettingsManager.swift
//  ScreenMarkerPro
//
//  Created on 2026-02-05.
//

import Foundation
import SwiftUI
import Combine
import Cocoa

// MARK: - Enums

enum BorderColorMode: String, CaseIterable, Identifiable {
    case randomGradient = "随机渐变"
    case singleColor = "单色固定"
    
    var id: String { self.rawValue }
}

enum LineStyle: String, CaseIterable, Identifiable {
    case solid = "实线"
    case dashed = "虚线"
    
    var id: String { self.rawValue }
}

enum KeyCastPosition: String, CaseIterable, Identifiable {
    case bottomLeft = "左下角"
    case topLeft = "左上角"
    case bottomRight = "右下角"
    case topRight = "右上角"
    case bottomCenter = "中间底部"
    case topCenter = "中间顶部"
    
    var id: String { self.rawValue }
    
    var alignment: Alignment {
        switch self {
        case .bottomLeft: return .bottomLeading
        case .topLeft: return .topLeading
        case .bottomRight: return .bottomTrailing
        case .topRight: return .topTrailing
        case .bottomCenter: return .bottom
        case .topCenter: return .top
        }
    }
    
    var isTopAligned: Bool {
        switch self {
        case .topLeft, .topRight, .topCenter:
            return true
        default:
            return false
        }
    }
}

// MARK: - SettingsManager

class SettingsManager: ObservableObject {
    
    static let shared = SettingsManager()
    
    // MARK: - Keys
    private let kBorderColorMode = "pref_borderColorMode"
    private let kSingleColorHex = "pref_singleColorHex"
    private let kLineStyle = "pref_lineStyle"
    private let kLineWidth = "pref_lineWidth"
    private let kCornerRadius = "pref_cornerRadius"
    private let kDuration = "pref_duration"
    
    // MARK: - KeyCast Settings
    // MARK: - KeyCast Settings
    private let kShowKeycasting = "pref_showKeycasting"
    private let kKeyCastPosition = "pref_keyCastPosition"
    private let kKeyCastModifierCommand = "pref_keyCastModifierCommand"
    private let kKeyCastModifierControl = "pref_keyCastModifierControl"
    private let kKeyCastModifierOption = "pref_keyCastModifierOption"
    private let kKeyCastModifierShift = "pref_keyCastModifierShift"
    private let kDrawHotkeyCommand = "pref_drawHotkeyCommand"
    private let kDrawHotkeyControl = "pref_drawHotkeyControl"
    private let kDrawHotkeyOption = "pref_drawHotkeyOption"
    private let kDrawHotkeyShift = "pref_drawHotkeyShift"
    
    // KeyCast Appearance Keys
    private let kKeyCastBgColor = "pref_keyCastBgColor"
    private let kKeyCastTextColor = "pref_keyCastTextColor"
    private let kKeyCastBorderColor = "pref_keyCastBorderColor"
    private let kKeyCastDuration = "pref_keyCastDuration"
    private let kKeyCastFontSize = "pref_keyCastFontSize"
    private let kKeyCastGroupTimeWindow = "pref_keyCastGroupTimeWindow"

    
    // MARK: - Appearance Settings
    
    @Published var borderColorMode: BorderColorMode {
        didSet {
            UserDefaults.standard.set(borderColorMode.rawValue, forKey: kBorderColorMode)
        }
    }
    
    @Published var singleColorHex: String {
        didSet {
            UserDefaults.standard.set(singleColorHex, forKey: kSingleColorHex)
        }
    }
    
    @Published var lineStyle: LineStyle {
        didSet {
            UserDefaults.standard.set(lineStyle.rawValue, forKey: kLineStyle)
        }
    }
    
    @Published var lineWidth: Double {
        didSet {
            UserDefaults.standard.set(lineWidth, forKey: kLineWidth)
        }
    }
    
    @Published var cornerRadius: Double {
        didSet {
            UserDefaults.standard.set(cornerRadius, forKey: kCornerRadius)
        }
    }
    
    // MARK: - Behavior Settings
    
    /// 停留时间 (秒)
    @Published var duration: Double {
        didSet {
            UserDefaults.standard.set(duration, forKey: kDuration)
        }
    }
    
    @Published var showKeycasting: Bool {
        didSet {
            UserDefaults.standard.set(showKeycasting, forKey: kShowKeycasting)
        }
    }
    
    @Published var keyCastPosition: KeyCastPosition {
        didSet {
            UserDefaults.standard.set(keyCastPosition.rawValue, forKey: kKeyCastPosition)
        }
    }

    @Published var keyCastModifierCommand: Bool {
        didSet { UserDefaults.standard.set(keyCastModifierCommand, forKey: kKeyCastModifierCommand) }
    }

    @Published var keyCastModifierControl: Bool {
        didSet { UserDefaults.standard.set(keyCastModifierControl, forKey: kKeyCastModifierControl) }
    }

    @Published var keyCastModifierOption: Bool {
        didSet { UserDefaults.standard.set(keyCastModifierOption, forKey: kKeyCastModifierOption) }
    }

    @Published var keyCastModifierShift: Bool {
        didSet { UserDefaults.standard.set(keyCastModifierShift, forKey: kKeyCastModifierShift) }
    }

    @Published var drawHotkeyCommand: Bool {
        didSet { UserDefaults.standard.set(drawHotkeyCommand, forKey: kDrawHotkeyCommand) }
    }

    @Published var drawHotkeyControl: Bool {
        didSet { UserDefaults.standard.set(drawHotkeyControl, forKey: kDrawHotkeyControl) }
    }

    @Published var drawHotkeyOption: Bool {
        didSet { UserDefaults.standard.set(drawHotkeyOption, forKey: kDrawHotkeyOption) }
    }

    @Published var drawHotkeyShift: Bool {
        didSet { UserDefaults.standard.set(drawHotkeyShift, forKey: kDrawHotkeyShift) }
    }
    
    @Published var keyCastBgColorHex: String {
        didSet { UserDefaults.standard.set(keyCastBgColorHex, forKey: kKeyCastBgColor) }
    }
    
    @Published var keyCastTextColorHex: String {
        didSet { UserDefaults.standard.set(keyCastTextColorHex, forKey: kKeyCastTextColor) }
    }
    
    @Published var keyCastBorderColorHex: String {
        didSet { UserDefaults.standard.set(keyCastBorderColorHex, forKey: kKeyCastBorderColor) }
    }
    
    @Published var keyCastDuration: Double {
        didSet { UserDefaults.standard.set(keyCastDuration, forKey: kKeyCastDuration) }
    }
    
    @Published var keyCastFontSize: Double {
        didSet { UserDefaults.standard.set(keyCastFontSize, forKey: kKeyCastFontSize) }
    }
    
    @Published var keyCastGroupTimeWindow: Double {
        didSet { UserDefaults.standard.set(keyCastGroupTimeWindow, forKey: kKeyCastGroupTimeWindow) }
    }
    
    // MARK: - Computed Properties
    
    var singleColor: Color {
        get { Color(hex: singleColorHex) ?? .red }
        set {
            if let hex = newValue.toHex() {
                singleColorHex = hex
            }
        }
    }
    
    var nsSingleColor: NSColor {
        return NSColor(singleColor)
    }
    
    var keyCastBgColor: Color {
        get { Color(hex: keyCastBgColorHex) ?? .black.opacity(0.6) }
        set { if let hex = newValue.toHex() { keyCastBgColorHex = hex } }
    }
    
    var keyCastTextColor: Color {
        get { Color(hex: keyCastTextColorHex) ?? .white }
        set { if let hex = newValue.toHex() { keyCastTextColorHex = hex } }
    }
    
    var keyCastBorderColor: Color {
        get { Color(hex: keyCastBorderColorHex) ?? .white.opacity(0.2) }
        set { if let hex = newValue.toHex() { keyCastBorderColorHex = hex } }
    }

    var keyCastTriggerModifiers: NSEvent.ModifierFlags {
        var modifiers: NSEvent.ModifierFlags = []
        if keyCastModifierCommand { modifiers.insert(.command) }
        if keyCastModifierControl { modifiers.insert(.control) }
        if keyCastModifierOption { modifiers.insert(.option) }
        if keyCastModifierShift { modifiers.insert(.shift) }
        return modifiers
    }

    var keyCastModifiersConfigured: Bool {
        !keyCastTriggerModifiers.isEmpty
    }

    var keyCastListeningDisplayText: String {
        var parts: [String] = []
        if keyCastModifierControl { parts.append("⌃Control") }
        if keyCastModifierOption { parts.append("⌥Option") }
        if keyCastModifierShift { parts.append("⇧Shift") }
        if keyCastModifierCommand { parts.append("⌘Command") }
        if parts.isEmpty {
            return "未勾选监听修饰键(不会触发回显)"
        }
        return parts.joined(separator: "+")
    }

    var keyCastingRuntimeEnabled: Bool {
        showKeycasting && keyCastModifiersConfigured
    }

    var drawingTriggerModifiers: NSEvent.ModifierFlags {
        var modifiers: NSEvent.ModifierFlags = []
        if drawHotkeyCommand { modifiers.insert(.command) }
        if drawHotkeyControl { modifiers.insert(.control) }
        if drawHotkeyOption { modifiers.insert(.option) }
        if drawHotkeyShift { modifiers.insert(.shift) }
        return modifiers
    }

    var drawingHotkeyIsConfigured: Bool {
        !drawingTriggerModifiers.isEmpty
    }

    var drawingHotkeyDisplayText: String {
        var parts: [String] = []
        if drawHotkeyControl { parts.append("⌃Control") }
        if drawHotkeyOption { parts.append("⌥Option") }
        if drawHotkeyShift { parts.append("⇧Shift") }
        if drawHotkeyCommand { parts.append("⌘Command") }
        if parts.isEmpty {
            return "未设置修饰键+右键(不会触发绘制)"
        }
        return "\(parts.joined(separator: "+"))+右键"
    }
    
    private init() {
        // Initialize from UserDefaults with Defaults
        UserDefaults.standard.register(defaults: [
            kBorderColorMode: BorderColorMode.randomGradient.rawValue,
            kSingleColorHex: "#FF3B30",
            kLineStyle: LineStyle.solid.rawValue,
            kLineWidth: 2.0,
            kCornerRadius: 6.0,
            kDuration: 1.0,
            kShowKeycasting: true,
            kKeyCastPosition: KeyCastPosition.bottomLeft.rawValue,
            kKeyCastModifierCommand: true,
            kKeyCastModifierControl: true,
            kKeyCastModifierOption: true,
            kKeyCastModifierShift: true,
            kDrawHotkeyCommand: true,
            kDrawHotkeyControl: false,
            kDrawHotkeyOption: false,
            kDrawHotkeyShift: false,


            
            kKeyCastBgColor: "#00000099", // Black with ~60% alpha
            kKeyCastTextColor: "#FFFFFF",
            kKeyCastBorderColor: "#FFFFFF33", // White with ~20% alpha
            kKeyCastDuration: 2.0,
            kKeyCastFontSize: 24.0,
            kKeyCastGroupTimeWindow: 1.0
        ])
        
        // Load properties
        let modeRaw = UserDefaults.standard.string(forKey: kBorderColorMode) ?? BorderColorMode.randomGradient.rawValue
        self.borderColorMode = BorderColorMode(rawValue: modeRaw) ?? .randomGradient
        
        self.singleColorHex = UserDefaults.standard.string(forKey: kSingleColorHex) ?? "#FF3B30"
        
        let styleRaw = UserDefaults.standard.string(forKey: kLineStyle) ?? LineStyle.solid.rawValue
        self.lineStyle = LineStyle(rawValue: styleRaw) ?? .solid
        
        self.lineWidth = UserDefaults.standard.double(forKey: kLineWidth)
        self.cornerRadius = UserDefaults.standard.double(forKey: kCornerRadius)

        self.duration = UserDefaults.standard.double(forKey: kDuration)
        
        self.showKeycasting = UserDefaults.standard.bool(forKey: kShowKeycasting)
        
        let positionRaw = UserDefaults.standard.string(forKey: kKeyCastPosition) ?? KeyCastPosition.bottomLeft.rawValue
        self.keyCastPosition = KeyCastPosition(rawValue: positionRaw) ?? .bottomLeft
        self.keyCastModifierCommand = UserDefaults.standard.bool(forKey: kKeyCastModifierCommand)
        self.keyCastModifierControl = UserDefaults.standard.bool(forKey: kKeyCastModifierControl)
        self.keyCastModifierOption = UserDefaults.standard.bool(forKey: kKeyCastModifierOption)
        self.keyCastModifierShift = UserDefaults.standard.bool(forKey: kKeyCastModifierShift)
        self.drawHotkeyCommand = UserDefaults.standard.bool(forKey: kDrawHotkeyCommand)
        self.drawHotkeyControl = UserDefaults.standard.bool(forKey: kDrawHotkeyControl)
        self.drawHotkeyOption = UserDefaults.standard.bool(forKey: kDrawHotkeyOption)
        self.drawHotkeyShift = UserDefaults.standard.bool(forKey: kDrawHotkeyShift)
        
        self.keyCastBgColorHex = UserDefaults.standard.string(forKey: kKeyCastBgColor) ?? "#00000099"
        self.keyCastTextColorHex = UserDefaults.standard.string(forKey: kKeyCastTextColor) ?? "#FFFFFF"
        self.keyCastBorderColorHex = UserDefaults.standard.string(forKey: kKeyCastBorderColor) ?? "#FFFFFF33"
        var durationVal = UserDefaults.standard.double(forKey: kKeyCastDuration)
        if durationVal == 0 { durationVal = 2.0 }
        self.keyCastDuration = durationVal
        
        var fontSizeVal = UserDefaults.standard.double(forKey: kKeyCastFontSize)
        if fontSizeVal == 0 { fontSizeVal = 24.0 }
        self.keyCastFontSize = fontSizeVal
        
        var groupWindowVal = UserDefaults.standard.double(forKey: kKeyCastGroupTimeWindow)
        if groupWindowVal == 0 { groupWindowVal = 1.0 }
        self.keyCastGroupTimeWindow = groupWindowVal
        
        print("🔧 SettingsManager Initialized:")
        print("   Mode: \(borderColorMode)")
        print("   Width: \(lineWidth)")
        print("   Duration: \(duration)")
    }
}
