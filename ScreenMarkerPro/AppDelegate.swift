//
//  AppDelegate.swift
//  ScreenMarkerPro
//
//  Created on 2026-02-05.
//

import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var overlayWindows: [OverlayWindow] = []
    var eventMonitor: EventMonitor?
    var drawingManager: DrawingManager?
    var menuBarManager: MenuBarManager?
    var keyCastWindow: KeyCastWindow?
    var keyCastHostingController: NSHostingController<KeyCastView>?
    var hasInitializedKeycast = false // 标记KeyCast是否已完成首次渲染
    private var hasCompletedPermissionSetup = false
    private var settingsCancellables = Set<AnyCancellable>()
    private var eventMonitorCancellables = Set<AnyCancellable>()
    private var permissionRecheckTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 强制输出到控制台
        print(String(repeating: "=", count: 50))
        print("🚀 ScreenMarker Pro 应用已启动！")
        print(String(repeating: "=", count: 50))
        NSLog("🚀 ScreenMarker Pro NSLog 测试")
        
        // 监听屏幕配置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenConfigurationChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // 第一步：初始化菜单栏（保证用户总能看到图标）
        setupMenuBar()
        
        // 第二步：检查辅助功能权限
        checkAndRequestPermission()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // 清理资源
        cancelPermissionRecheck()
        eventMonitor?.stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Private Methods
    
    private func checkAndRequestPermission() {
        NSLog("🔍 开始检查辅助功能权限...")
        let hasPermission = AccessibilityManager.shared.checkAccessibilityPermission()
        
        if hasPermission {
            attemptPermissionDependentSetup()
        } else {
            print("⚠️ 未获得辅助功能权限，请求授权...")
            NSLog("⚠️ 未获得辅助功能权限，请求授权...")
            menuBarManager?.updatePermissionStatus(.accessibilityMissing)
            AccessibilityManager.shared.showPermissionAlert { [weak self] openedSettings in
                if openedSettings {
                    self?.schedulePermissionRecheck()
                }
            }
        }
    }
    
    private func schedulePermissionRecheck() {
        cancelPermissionRecheck()
        
        // 每2秒检查一次权限，直到获得授权
        permissionRecheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            guard AccessibilityManager.shared.checkAccessibilityPermission() else { return }

            if self.attemptPermissionDependentSetup() {
                timer.invalidate()
                self.permissionRecheckTimer = nil
            }
        }
        permissionRecheckTimer?.tolerance = 0.5
    }
    
    @discardableResult
    private func setupOverlayAndEvents() -> Bool {
        if hasCompletedPermissionSetup {
            return true
        }
        
        // 创建全屏透明覆盖窗口
        setupOverlayWindows()
        
        // 创建按键回显窗口
        setupKeyCastWindow()
        
        // 创建绘制管理器
        if let drawingManager {
            drawingManager.updateOverlayWindows(overlayWindows)
        } else {
            drawingManager = DrawingManager(overlayWindows: overlayWindows)
        }
        
        // 启动事件监听
        let success = setupEventMonitor()
        hasCompletedPermissionSetup = success
        if !success {
            eventMonitor?.stop()
            eventMonitor = nil
        }
        return success
    }
    
    private func setupMenuBar() {
        menuBarManager = MenuBarManager()
        menuBarManager?.updateDrawingHotkeyHint(SettingsManager.shared.drawingHotkeyDisplayText)
        menuBarManager?.onOpenAccessibilitySettings = { [weak self] in
            self?.schedulePermissionRecheck()
        }
        menuBarManager?.onRetryPermissionCheck = { [weak self] in
            self?.retryPermissionSetup()
        }
        bindHotkeyHintUpdates()
        print("✅ 菜单栏已创建")
    }
    

    
    
    private func setupKeyCastWindow() {
        if keyCastWindow != nil { return }
        
        // 关键修复：确保窗口出现在鼠标所在的屏幕
        let mouseLoc = NSEvent.mouseLocation
        let activeScreen = NSScreen.screens.first { NSMouseInRect(mouseLoc, $0.frame, false) } ?? NSScreen.main
        
        let window = KeyCastWindow(screen: activeScreen)
        
        let keyCastView = KeyCastView()
        let hostingController = NSHostingController(rootView: keyCastView)
        
        // 关键：SwiftUI Host View背景也要透明
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        window.contentViewController = hostingController
        
        self.keyCastWindow = window
        self.keyCastHostingController = hostingController
        
        // 关键逻辑：只有在按键触发时才更新窗口位置 (Lazy Follow)
        // 这同时也解决了启动延迟问题，因为第一次按键时会立即检查并移动窗口
        KeyCastManager.shared.onKeyEvent = { [weak self] in
            guard SettingsManager.shared.keyCastingRuntimeEnabled else { return }
            self?.checkMouseScreen()
        }
        
        syncKeyCastRuntimeState(forceLayoutRefresh: true)
        
        print("✅ 按键回显窗口已创建 Frame: \(window.frame)")
        print("   Window Level: \(window.level.rawValue) (CGWindowLevel)")
        print("   Is Visible: \(window.isVisible)")
        print("   Is On Screen: \(window.isOnActiveSpace)")
        print("   Alpha: \(window.alphaValue)")
        print("   showKeycasting: \(SettingsManager.shared.showKeycasting)")
        print("   Content View Controller: \(String(describing: window.contentViewController))")
    }
    
    private func setupOverlayWindows() {
        // 清理旧窗口
        overlayWindows.forEach { $0.close() }
        overlayWindows.removeAll()
        
        // 为每个屏幕创建一个OverlayWindow
        for (index, screen) in NSScreen.screens.enumerated() {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window.orderFrontRegardless()
            overlayWindows.append(window)
            
            print("📺 屏幕 \(index): \(screen.frame)")
            print("   窗口 \(index): Created at \(window.frame)")
        }
        
        print("✅ 已创建 \(overlayWindows.count) 个覆盖窗口")
    }
    
    @objc private func handleScreenConfigurationChange() {
        print("📺 监听到屏幕配置变化，重建覆盖窗口...")
        setupOverlayWindows()
        // 更新按键回显窗口
        if SettingsManager.shared.keyCastingRuntimeEnabled, let screen = NSScreen.main {
            keyCastWindow?.updateFrame(for: screen)
            hasInitializedKeycast = false
            checkMouseScreen(forceLayoutRefresh: true)
        } else {
            hasInitializedKeycast = false
        }
        // 更新DrawingManager的窗口列表
        drawingManager?.updateOverlayWindows(overlayWindows)
    }

    @objc private func handleAppDidBecomeActive() {
        if !hasCompletedPermissionSetup, AccessibilityManager.shared.checkAccessibilityPermission() {
            _ = attemptPermissionDependentSetup()
        }
    }
    
    /// 创建测试窗口验证显示是否正常
    // 方法已移除
    // private func createTestWindow() { ... }
    
    @discardableResult
    private func setupEventMonitor() -> Bool {
        eventMonitorCancellables.removeAll()
        eventMonitor = EventMonitor()
        
        // 设置绘制回调
        eventMonitor?.onDrawing = { [weak self] startPoint, endPoint, isFinished in
            self?.drawingManager?.updateDrawing(from: startPoint, to: endPoint, isFinished: isFinished)
        }
        eventMonitor?.onDrawingCancelled = { [weak self] in
            self?.drawingManager?.cancelCurrentDrawing()
        }
        
        // 监听鼠标移动以更新KeyCastWindow位置 (当鼠标跨越屏幕时)
        // 移除：改为在按键触发时检测位置 (Lazy follow)
        // NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
        //    self?.checkMouseScreen()
        // }
        
        // 启动监听
        let success = eventMonitor?.start() ?? false
        if success {
            syncKeyCastRuntimeState()
            
            Publishers.CombineLatest(
                SettingsManager.shared.$showKeycasting.removeDuplicates(),
                Publishers.CombineLatest4(
                    SettingsManager.shared.$keyCastModifierCommand.removeDuplicates(),
                    SettingsManager.shared.$keyCastModifierControl.removeDuplicates(),
                    SettingsManager.shared.$keyCastModifierOption.removeDuplicates(),
                    SettingsManager.shared.$keyCastModifierShift.removeDuplicates()
                )
            )
                .sink { [weak self] _, _ in
                    self?.syncKeyCastRuntimeState(forceLayoutRefresh: SettingsManager.shared.keyCastingRuntimeEnabled)
                }
                .store(in: &eventMonitorCancellables)
            
            print("✅ 事件监听已启动 - 请使用 \(SettingsManager.shared.drawingHotkeyDisplayText) 来绘制标记")
        } else {
            print("❌ 事件监听启动失败，请检查辅助功能权限")
        }
        return success
    }

    private func syncKeyCastRuntimeState(forceLayoutRefresh: Bool = false) {
        let runtimeEnabled = SettingsManager.shared.keyCastingRuntimeEnabled
        eventMonitor?.setKeyboardMonitoringEnabled(runtimeEnabled)
        
        if !runtimeEnabled {
            KeyCastManager.shared.keys.removeAll()
        }
        
        syncKeyCastWindowVisibility(enabled: runtimeEnabled, forceLayoutRefresh: forceLayoutRefresh)
    }

    private func syncKeyCastWindowVisibility(enabled: Bool, forceLayoutRefresh: Bool = false) {
        guard let window = keyCastWindow else { return }
        
        if enabled {
            window.orderFrontRegardless()
            
            guard forceLayoutRefresh else { return }
            
            // 重新显示时做双阶段布局同步，避免SwiftUI首帧文本偶发丢失
            DispatchQueue.main.async { [weak self] in
                guard SettingsManager.shared.keyCastingRuntimeEnabled else { return }
                self?.checkMouseScreen(forceLayoutRefresh: true)
                print("✅ 已触发KeyCast渲染同步(阶段1)")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard SettingsManager.shared.keyCastingRuntimeEnabled else { return }
                self?.checkMouseScreen(forceLayoutRefresh: true)
                print("✅ 已触发KeyCast渲染同步(阶段2)")
            }
        } else {
            hasInitializedKeycast = false
            window.orderOut(nil)
        }
    }

    private func cancelPermissionRecheck() {
        permissionRecheckTimer?.invalidate()
        permissionRecheckTimer = nil
    }

    @discardableResult
    private func attemptPermissionDependentSetup() -> Bool {
        print("🔁 尝试完成权限后的功能初始化...")
        let success = setupOverlayAndEvents()
        if success {
            cancelPermissionRecheck()
            print("✅ 已获得辅助功能权限并完成事件监听初始化")
            NSLog("✅ 已获得辅助功能权限并完成事件监听初始化")
            menuBarManager?.updatePermissionStatus(.ready)
        } else {
            print("⏳ 权限已授予，但事件监听尚未稳定，稍后重试")
            menuBarManager?.updatePermissionStatus(.retryInitialization)
            if permissionRecheckTimer == nil {
                schedulePermissionRecheck()
            }
        }
        return success
    }

    private func retryPermissionSetup() {
        print("🔄 用户手动触发权限重新检测与初始化重试")
        cancelPermissionRecheck()

        let hasPermission = AccessibilityManager.shared.checkAccessibilityPermission()
        guard hasPermission else {
            menuBarManager?.updatePermissionStatus(.accessibilityMissing)
            AccessibilityManager.shared.openSystemPreferences()
            schedulePermissionRecheck()
            return
        }

        resetPermissionDependentSetupState()
        if !attemptPermissionDependentSetup() {
            schedulePermissionRecheck()
        }
    }

    private func resetPermissionDependentSetupState() {
        hasCompletedPermissionSetup = false
        hasInitializedKeycast = false
        eventMonitorCancellables.removeAll()
        eventMonitor?.stop()
        eventMonitor = nil
        drawingManager?.clearAll()
        drawingManager = nil
        overlayWindows.forEach { $0.close() }
        overlayWindows.removeAll()
    }
    
    private func checkMouseScreen(forceLayoutRefresh: Bool = false) {
        guard let window = keyCastWindow else { return }
        let mouseLoc = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) {
            
            // 首次调用、屏幕发生变化，或外部显式要求时，执行一次确定性布局刷新
            let needsRefresh = forceLayoutRefresh || !hasInitializedKeycast || window.screen != screen
            
            if needsRefresh {
                // 首次渲染或强制刷新时，即便在同一屏也做一次frame重绑定，确保文本层激活
                let shouldForceMove = forceLayoutRefresh || !hasInitializedKeycast
                window.moveToScreen(screen, force: shouldForceMove)
                
                // 不重建rootView，仅做布局和重绘，避免首帧事件与订阅时序冲突
                keyCastHostingController?.view.needsLayout = true
                keyCastHostingController?.view.layoutSubtreeIfNeeded()
                keyCastHostingController?.view.needsDisplay = true
                keyCastHostingController?.view.displayIfNeeded()
                window.contentView?.needsLayout = true
                window.contentView?.layoutSubtreeIfNeeded()
                window.displayIfNeeded()
                
                hasInitializedKeycast = true
            }
        }
    }

    private func bindHotkeyHintUpdates() {
        Publishers.CombineLatest4(
            SettingsManager.shared.$drawHotkeyCommand.removeDuplicates(),
            SettingsManager.shared.$drawHotkeyControl.removeDuplicates(),
            SettingsManager.shared.$drawHotkeyOption.removeDuplicates(),
            SettingsManager.shared.$drawHotkeyShift.removeDuplicates()
        )
        .sink { [weak self] _, _, _, _ in
            let hint = SettingsManager.shared.drawingHotkeyDisplayText
            self?.menuBarManager?.updateDrawingHotkeyHint(hint)
        }
        .store(in: &settingsCancellables)
    }
}
