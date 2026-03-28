//
//  SettingsView.swift
//  ScreenMarkerPro
//
//  Created on 2026-02-05.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    // 预设颜色列表 (模仿 macOS 系统色板)
    private let presetColorHexes: [String] = [
        // Row 1: Grays
        "#000000", "#262626", "#4D4D4D", "#808080", "#B3B3B3", "#D9D9D9", "#FFFFFF",
        // Row 2: Reds
        "#800000", "#A52A2A", "#FF0000", "#FF5733", "#FFC0CB",
        // Row 3: Oranges/Yellows
        "#8B4500", "#D2691E", "#FF8C00", "#FFA500", "#FFD700", "#FFFF00",
        // Row 4: Greens
        "#006400", "#228B22", "#32CD32", "#00FF00", "#90EE90", "#00FA9A",
        // Row 5: Blues
        "#00008B", "#0000CD", "#0000FF", "#1E90FF", "#00BFFF", "#E0FFFF",
        // Row 6: Purples/Pinks
        "#4B0082", "#800080", "#8A2BE2", "#FF00FF", "#EE82EE", "#DDA0DD",
        // Row 7: Browns/Others
        "#8B4513", "#A0522D", "#CD853F", "#DEB887", "#F5DEB3", "#FFF8DC"
    ]

    private var presetColors: [Color] {
        presetColorHexes.compactMap { Color(hex: $0) }
    }
    
    init() {}
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("偏好设置")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 屏幕标记设置
                    GroupBox(label: Label("屏幕标记设置", systemImage: "rectangle.dashed")) {
                        VStack(alignment: .leading, spacing: 16) {
                            modifierSelectionSection(
                                title: "绘制触发键",
                                summary: settings.drawingHotkeyDisplayText,
                                detail: "绘制需要按住这里勾选的修饰键，再配合右键拖拽才会触发。",
                                warning: "请至少勾选一个修饰键，否则右键拖拽不会触发绘制。",
                                isConfigured: settings.drawingHotkeyIsConfigured,
                                command: $settings.drawHotkeyCommand,
                                control: $settings.drawHotkeyControl,
                                option: $settings.drawHotkeyOption,
                                shift: $settings.drawHotkeyShift,
                                onSelectAll: {
                                    settings.drawHotkeyCommand = true
                                    settings.drawHotkeyControl = true
                                    settings.drawHotkeyOption = true
                                    settings.drawHotkeyShift = true
                                },
                                onClear: {
                                    settings.drawHotkeyCommand = false
                                    settings.drawHotkeyControl = false
                                    settings.drawHotkeyOption = false
                                    settings.drawHotkeyShift = false
                                }
                            )

                            Divider()

                            Text("标记外观")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("颜色模式:")
                                    .frame(width: 80, alignment: .trailing)

                                Picker("", selection: $settings.borderColorMode) {
                                    ForEach(BorderColorMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }

                            if settings.borderColorMode == .singleColor {
                                VStack(alignment: .leading, spacing: 10) {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 18, maximum: 18), spacing: 6)], spacing: 6) {
                                        ForEach(presetColors, id: \.self) { color in
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(color)
                                                .frame(width: 18, height: 18)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.white, lineWidth: settings.singleColor == color ? 2 : 0)
                                                        .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 0)
                                                )
                                                .onTapGesture {
                                                    settings.singleColor = color
                                                }
                                        }
                                    }
                                    .padding(10)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                                    .padding(.leading, 80)
                                    .padding(.trailing, 20)

                                    HStack {
                                        Spacer()
                                        ColorPicker("自定义颜色...", selection: $settings.singleColor)
                                            .labelsHidden()
                                            .frame(height: 20)
                                        Text("自定义颜色...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.leading, 80)
                                }
                            }

                            Divider().padding(.vertical, 4)

                            HStack {
                                Text("线段样式:")
                                    .frame(width: 80, alignment: .trailing)

                                Picker("", selection: $settings.lineStyle) {
                                    ForEach(LineStyle.allCases) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }

                            HStack {
                                Text("边框粗细:")
                                    .frame(width: 80, alignment: .trailing)

                                Slider(value: $settings.lineWidth, in: 1.0...10.0, step: 0.5)

                                TextField("1.0", value: $settings.lineWidth, formatter: NumberFormatter.oneDecimal)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 50)
                                    .multilineTextAlignment(.trailing)

                                Text("pt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("圆角大小:")
                                    .frame(width: 80, alignment: .trailing)

                                Slider(value: $settings.cornerRadius, in: 0.0...50.0, step: 1.0)

                                TextField("6", value: $settings.cornerRadius, formatter: NumberFormatter.noDecimal)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 50)
                                    .multilineTextAlignment(.trailing)

                                Text("px")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            Text("标记行为")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("停留时间:")
                                    .frame(width: 80, alignment: .trailing)
                                Slider(value: $settings.duration, in: 0.5...5.0, step: 0.5)
                                Text("\(String(format: "%.1f", settings.duration)) s")
                                    .font(.monospacedDigit(.body)())
                                    .frame(width: 50, alignment: .leading)
                            }

                            Text("此设置控制标记框完全不透明的停留时间，不包含淡出动画时间。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 88)
                        }
                        .padding(8)
                    }

                    // MARK: - 按键回显设置
                    GroupBox(label: Label("按键回显设置(Keycasting)", systemImage: "keyboard")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("启用按键回显", isOn: $settings.showKeycasting)

                            if settings.showKeycasting {
                                Divider()

                                modifierSelectionSection(
                                    title: "监听修饰键",
                                    summary: settings.keyCastListeningDisplayText,
                                    detail: "只有勾选的修饰键参与时才会监听，而且必须是修饰键+另一个按键，至少两个键同时按下，才会触发回显。",
                                    warning: "请至少勾选一个修饰键，否则不会触发按键回显。",
                                    isConfigured: settings.keyCastModifiersConfigured,
                                    command: $settings.keyCastModifierCommand,
                                    control: $settings.keyCastModifierControl,
                                    option: $settings.keyCastModifierOption,
                                    shift: $settings.keyCastModifierShift,
                                    onSelectAll: {
                                        settings.keyCastModifierCommand = true
                                        settings.keyCastModifierControl = true
                                        settings.keyCastModifierOption = true
                                        settings.keyCastModifierShift = true
                                    },
                                    onClear: {
                                        settings.keyCastModifierCommand = false
                                        settings.keyCastModifierControl = false
                                        settings.keyCastModifierOption = false
                                        settings.keyCastModifierShift = false
                                    }
                                )

                                HStack {
                                    Text("显示位置:")
                                        .frame(width: 80, alignment: .trailing)

                                    Picker("", selection: $settings.keyCastPosition) {
                                        ForEach(KeyCastPosition.allCases) { pos in
                                            Text(pos.rawValue).tag(pos)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 130)
                                }

                                Divider()

                                Text("样式自定义")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Group {
                                    HStack {
                                        ColorPicker("背景颜色", selection: $settings.keyCastBgColor)
                                        Spacer()
                                        ColorPicker("文字颜色", selection: $settings.keyCastTextColor)
                                    }

                                    HStack {
                                        ColorPicker("边框颜色", selection: $settings.keyCastBorderColor)
                                        Spacer()
                                    }

                                    HStack {
                                        Text("停留时间:")
                                        Slider(value: $settings.keyCastDuration, in: 0.5...10.0, step: 0.5)
                                        Text("\(String(format: "%.1f", settings.keyCastDuration)) s")
                                            .font(.monospacedDigit(.body)())
                                            .frame(width: 50, alignment: .leading)
                                    }

                                    HStack {
                                        Text("连按聚合:")
                                        Slider(value: $settings.keyCastGroupTimeWindow, in: 0.2...5.0, step: 0.1)
                                        Text("\(String(format: "%.1f", settings.keyCastGroupTimeWindow)) s")
                                            .font(.monospacedDigit(.body)())
                                            .frame(width: 50, alignment: .leading)
                                    }

                                    HStack {
                                        Text("字体大小:")
                                        Slider(value: $settings.keyCastFontSize, in: 12.0...60.0, step: 1.0)
                                        Text("\(Int(settings.keyCastFontSize)) pt")
                                            .font(.monospacedDigit(.body)())
                                            .frame(width: 50, alignment: .leading)
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // 底部操作区
            HStack {
                Button("重置默认") {
                    resetDefaults()
                }
                Spacer()
                Button("关闭") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 450, height: 620)
    }
    
    private func resetDefaults() {
        settings.borderColorMode = .randomGradient
        settings.lineStyle = .solid
        settings.lineWidth = 2.0
        settings.cornerRadius = 6.0
        settings.duration = 1.0
        settings.singleColorHex = "#FF3B30"
        
        settings.showKeycasting = true
        settings.keyCastPosition = .bottomLeft
        settings.keyCastModifierCommand = true
        settings.keyCastModifierControl = true
        settings.keyCastModifierOption = true
        settings.keyCastModifierShift = true
        settings.drawHotkeyCommand = true
        settings.drawHotkeyControl = false
        settings.drawHotkeyOption = false
        settings.drawHotkeyShift = false
        
        settings.keyCastBgColorHex = "#00000099"
        settings.keyCastTextColorHex = "#FFFFFF"
        settings.keyCastBorderColorHex = "#FFFFFF33"
        settings.keyCastDuration = 2.0
        settings.keyCastGroupTimeWindow = 1.0
        settings.keyCastFontSize = 24.0
    }

    @ViewBuilder
    private func modifierSelectionSection(
        title: String,
        summary: String,
        detail: String,
        warning: String,
        isConfigured: Bool,
        command: Binding<Bool>,
        control: Binding<Bool>,
        option: Binding<Bool>,
        shift: Binding<Bool>,
        onSelectAll: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                modifierActionButton(title: "全选", action: onSelectAll)
                modifierActionButton(title: "清空", action: onClear)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                hotkeyToggle("⌘Command", isOn: command)
                hotkeyToggle("⌃Control", isOn: control)
                hotkeyToggle("⌥Option", isOn: option)
                hotkeyToggle("⇧Shift", isOn: shift)
            }

            Text("当前:\(summary)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)

            if !isConfigured {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private func hotkeyToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .toggleStyle(.checkbox)
    }

    private func modifierActionButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
    }
}

extension NumberFormatter {
    static var oneDecimal: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }
    
    static var noDecimal: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
}
