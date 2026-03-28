import SwiftUI

struct KeyCastView: View {
    @ObservedObject var manager = KeyCastManager.shared
    @ObservedObject var settings = SettingsManager.shared
    
    private var topPadding: CGFloat {
        settings.keyCastPosition.isTopAligned ? 40 : 0
    }
    
    private var bottomPadding: CGFloat {
        settings.keyCastPosition.isTopAligned ? 0 : 40
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(manager.keys) { item in
                KeyCastRow(item: item)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            

        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
        .padding(.horizontal, 40) // 增加水平边距
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: settings.keyCastPosition.alignment)
    }
}

struct KeyCastRow: View {
    let item: KeyCastItem
    @ObservedObject var settings = SettingsManager.shared
    
    private var visibleText: String {
        let trimmed = item.displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "?" : item.displayText
    }
    
    var body: some View {


        Text(visibleText)
            .font(.system(size: settings.keyCastFontSize, weight: .bold, design: .default))
            .foregroundColor(settings.keyCastTextColor)
            .padding(.horizontal, settings.keyCastFontSize * 0.6) // 动态水平边距
            .padding(.vertical, settings.keyCastFontSize * 0.4)   // 动态垂直边距
            .background(settings.keyCastBgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(settings.keyCastBorderColor, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if item.count > 1 {
                    Text("×\(item.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                        .offset(x: 8, y: -8)
                        .shadow(radius: 2)
                }
            }
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

}
