import Cocoa

/// 全屏透明覆盖窗口，用于在屏幕最顶层绘制标记
/// 使用NSWindow而不是NSPanel以确保正确显示
class OverlayWindow: NSWindow {
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        // 直接使用传入的rect (针对特定屏幕)
        super.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: false)
        
        configureWindow()
        // 移除屏幕变化监听，由AppDelegate重建窗口
    }
    
    private func configureWindow() {
        // 窗口层级：使用screenSaver确保在全屏应用之上
        self.level = .screenSaver
        
        // 透明背景 - 关键配置
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        // 点击穿透
        self.ignoresMouseEvents = true
        
        // 跨桌面支持
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        // 创建contentView
        let contentView = NSView(frame: self.contentRect(forFrameRect: self.frame))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = .clear
        self.contentView = contentView
        
        print("✅ OverlayWindow配置完成: \(self.frame)")
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
