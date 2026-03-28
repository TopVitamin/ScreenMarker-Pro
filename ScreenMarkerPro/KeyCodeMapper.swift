import Cocoa
import Carbon

/// 负责将键盘扫描码转换为用户友好的显示符号
class KeyCodeMapper {
    static let shared = KeyCodeMapper()
    
    // 特殊按键映射表 (Apple Style)
    private let specialKeys: [Int: String] = [
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Space: "␣",
        kVK_Delete: "⌫",
        kVK_Escape: "⎋",
        kVK_Command: "⌘",
        kVK_Shift: "⇧",
        kVK_CapsLock: "⇪",
        kVK_Option: "⌥",
        kVK_Control: "⌃",
        kVK_RightShift: "⇧",
        kVK_RightOption: "⌥",
        kVK_RightControl: "⌃",
        kVK_Function: "Fn",
        kVK_F17: "F17", // FKeys usually mapped automatically, but just in case
        kVK_VolumeUp: "🔊",
        kVK_VolumeDown: "🔉",
        kVK_Mute: "🔇",
        kVK_Help: "?⃝",
        kVK_Home: "↖",
        kVK_PageUp: "⇞",
        kVK_ForwardDelete: "⌦",
        kVK_End: "↘",
        kVK_PageDown: "⇟",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_DownArrow: "↓",
        kVK_UpArrow: "↑"
    ]
    
    private init() {}
    
    func isModifier(_ keyCode: UInt16) -> Bool {
        let code = Int(keyCode)
        return code == kVK_Command ||
               code == kVK_Shift ||
               code == kVK_CapsLock ||
               code == kVK_Option ||
               code == kVK_Control ||
               code == kVK_RightShift ||
               code == kVK_RightOption ||
               code == kVK_RightControl ||
               code == kVK_Function
    }
    
    /// 将 CGKeyCode 转换为显示字符
    func map(keyCode: UInt16) -> String? {
        // 1. 检查特殊按键
        if let special = specialKeys[Int(keyCode)] {
            return special
        }
        
        // 2. 尝试使用 TIS API 获取对应键盘布局下的字符
        return string(from: keyCode)
    }
    
    private func string(from keyCode: UInt16) -> String? {
        // 使用 Carbon TIS 框架转换按键码
        // 这里简化实现，主要针对字母和数字
        // 实际生产环境可能需要更复杂的 TISInputSource 逻辑来处理不同语言布局
        // 但对于演示用途，基本的 ASCII 映射通常足够（假设 US 键盘布局，或回退到 code）
        
        // 临时简化：直接处理 ASCII 范围的按键，复杂符号后续优化
        // 为了稳定性，这里先手动映射常用字符，避免 Carbon 复杂调用导致的崩溃风险
        
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_9: return "9"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Grave: return "`"
        case kVK_ANSI_KeypadDecimal: return "."
        case kVK_ANSI_KeypadMultiply: return "*"
        case kVK_ANSI_KeypadPlus: return "+"
        case kVK_ANSI_KeypadClear: return "Clear"
        case kVK_ANSI_KeypadDivide: return "/"
        case kVK_ANSI_KeypadEnter: return "↩"
        case kVK_ANSI_KeypadMinus: return "-"
        case kVK_ANSI_KeypadEquals: return "="
        case kVK_ANSI_Keypad0: return "0"
        case kVK_ANSI_Keypad1: return "1"
        case kVK_ANSI_Keypad2: return "2"
        case kVK_ANSI_Keypad3: return "3"
        case kVK_ANSI_Keypad4: return "4"
        case kVK_ANSI_Keypad5: return "5"
        case kVK_ANSI_Keypad6: return "6"
        case kVK_ANSI_Keypad7: return "7"
        case kVK_ANSI_Keypad8: return "8"
        case kVK_ANSI_Keypad9: return "9"
        default: return nil
        }
    }
}
