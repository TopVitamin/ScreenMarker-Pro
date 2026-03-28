import Cocoa

class KeyCastWindow: NSWindow {
    
    init(screen: NSScreen? = NSScreen.main) {
        // 创建全屏透明窗口，覆盖在最上层但允许点击穿透
        let targetScreen = screen ?? NSScreen.main
        let screenRect = targetScreen?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        
        super.init(
            contentRect: screenRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 2) // Ensure above OverlayWindow
        self.alphaValue = 1.0 // 确保窗口不透明
        
        // 关键：允许鼠标点击穿透窗口
        self.ignoresMouseEvents = true
        
        // 确保窗口不占用 Dock 和 Command+Tab
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
    }
    
    /// 更新窗口尺寸以适应当前屏幕
    func updateFrame(for screen: NSScreen) {
        self.setFrame(screen.frame, display: true)
    }
    
    /// 将窗口移动到指定屏幕
    /// - Parameters:
    ///   - screen: 目标屏幕
    ///   - force: 为true时即使是同一屏也会重新setFrame，修复首帧渲染未激活的问题
    func moveToScreen(_ screen: NSScreen, force: Bool = false) {
        if !force && self.screen == screen { return }
        self.setFrame(screen.frame, display: true)
        self.contentView?.needsLayout = true
        self.contentView?.layoutSubtreeIfNeeded()
        self.displayIfNeeded()
        self.orderFrontRegardless()
    }
}

