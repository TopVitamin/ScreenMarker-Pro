//
//  EventMonitor.swift
//  ScreenMarkerPro
//
//  Created on 2026-02-05.
//

import Cocoa

/// 鼠标绘制事件监听器
class EventMonitor {
    
    // MARK: - Properties
    
    private var mouseTap: CFMachPort?
    private var mouseRunLoopSource: CFRunLoopSource?
    
    private var keyboardTap: CFMachPort?
    private var keyboardRunLoopSource: CFRunLoopSource?
    private var keyboardMonitoringEnabled = true
    
    /// 绘制回调：(startPoint, endPoint, isFinished)
    var onDrawing: ((NSPoint, NSPoint, Bool) -> Void)?
    var onDrawingCancelled: (() -> Void)?
    
    private var isDrawing = false
    private var startPoint: NSPoint = .zero
    private var currentPoint: NSPoint = .zero
    private var dragEventCount = 0
    private let supportedModifierMask: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
    
    // MARK: - Lifecycle
    
    init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// 启动事件监听
    func start() -> Bool {
        // 1. 设置鼠标Tap (Active Filter, defaultTap)
        if mouseTap == nil {
            let mouseMask = (1 << CGEventType.rightMouseDown.rawValue) |
                           (1 << CGEventType.rightMouseDragged.rawValue) |
                           (1 << CGEventType.rightMouseUp.rawValue)
            
            if let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap, // 需要拦截
                eventsOfInterest: CGEventMask(mouseMask),
                callback: { proxy, type, event, refcon in
                    let monitor = Unmanaged<EventMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                    return monitor.handleMouseEvent(proxy: proxy, type: type, event: event)
                },
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            ) {
                self.mouseTap = tap
                let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
                self.mouseRunLoopSource = source
                CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
                CGEvent.tapEnable(tap: tap, enable: true)
            } else {
                print("❌ 无法创建鼠标事件Tap")
                return false
            }
        }
        
        // 2. 设置键盘Tap (Passive Listener, listenOnly) -> 绝不卡死输入
        if keyboardTap == nil {
            let keyMask = (1 << CGEventType.keyDown.rawValue) |
                         (1 << CGEventType.flagsChanged.rawValue)
            
            if let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly, // 关键：只监听，不拦截，不阻塞
                eventsOfInterest: CGEventMask(keyMask),
                callback: { proxy, type, event, refcon in
                    let monitor = Unmanaged<EventMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                    // Passive tap callback allows returning nil, but return event is ignored anyway
                    monitor.handleKeyboardEvent(type: type, event: event)
                    return Unmanaged.passUnretained(event)
                },
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            ) {
                self.keyboardTap = tap
                let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
                self.keyboardRunLoopSource = source
                CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
                CGEvent.tapEnable(tap: tap, enable: keyboardMonitoringEnabled)
            } else {
                print("❌ 无法创建键盘事件Tap")
                // 键盘失败不应阻止鼠标功能，继续返回成功
            }
        }
        
        print("✅ EventMonitor启动成功 (Mouse: Active, Keyboard: Passive)")
        return true
    }
    
    /// 动态启停键盘监听，避免在关闭按键回显时持续监听键盘
    func setKeyboardMonitoringEnabled(_ enabled: Bool) {
        keyboardMonitoringEnabled = enabled
        if let tap = keyboardTap {
            CGEvent.tapEnable(tap: tap, enable: enabled)
        }
    }
    
    /// 停止事件监听
    func stop() {
        if let tap = mouseTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = mouseRunLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            mouseTap = nil
            mouseRunLoopSource = nil
        }
        
        if let tap = keyboardTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = keyboardRunLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            keyboardTap = nil
            keyboardRunLoopSource = nil
        }
        
        print("EventMonitor已停止")
    }
    
    // MARK: - Private Methods
    
    /// 处理捕获的事件
    /// 处理键盘事件 (Passive)
    private func handleKeyboardEvent(type: CGEventType, event: CGEvent) {
        // Fast path check
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
             if let tap = self.keyboardTap {
                 CGEvent.tapEnable(tap: tap, enable: keyboardMonitoringEnabled)
             }
             return
        }
        
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
        
        // 异步分发，绝不阻塞
        DispatchQueue.main.async {
            KeyCastManager.shared.handleKeyEvent(keyCode: keyCode, modifiers: modifiers)
        }
    }

    /// 处理鼠标事件 (Active)
    private func handleMouseEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        
        // 1. 优先处理Tap被禁用的情况
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("⚠️ MouseEventTap被禁用，尝试重新启用...")
            if let tap = self.mouseTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            cancelDrawingIfNeeded()
            return Unmanaged.passUnretained(event)
        }
        
        // 3. 安全访问事件属性 (放入autoreleasepool以降低内存压力)
        return autoreleasepool { () -> Unmanaged<CGEvent>? in
            let isTriggerPressed = isDrawingTriggerPressed(flags: event.flags)
            // 使用unflipped全局坐标(左下角原点)，与NSWindow屏幕坐标体系保持一致
            let location = event.unflippedLocation
            
            // 特殊处理：绘制中如果触发组合键被松开，立即结束绘制并放行后续事件
            if isDrawing && !isTriggerPressed && (type == .rightMouseDragged || type == .rightMouseUp) {
                print("⚠️ 绘制中触发键被松开，强制结束绘制")
                cancelDrawingIfNeeded()
                return Unmanaged.passUnretained(event)
            }
            
            // 只有在按下用户配置的触发键时才处理右键事件
            guard isTriggerPressed else {
                if isDrawing {
                    print("⚠️ 触发键未按下，重置绘制状态")
                    cancelDrawingIfNeeded()
                }
                return Unmanaged.passUnretained(event)
            }
            
            switch type {
            case .rightMouseDown:
                // 开始绘制
                isDrawing = true
                dragEventCount = 0
                startPoint = location
                currentPoint = location
                
                print("🎨 开始绘制 - 起点: (\(Int(location.x)), \(Int(location.y)))")
                
                // 拦截事件，防止弹出右键菜单
                return nil
                
            case .rightMouseDragged:
                if isDrawing {
                    dragEventCount += 1
                    currentPoint = location
                    
                    // 回调通知更新矩形
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.onDrawing?(self.startPoint, self.currentPoint, false)
                    }
                    
                    // 拦截事件
                    return nil
                }
                
            case .rightMouseUp:
                if isDrawing {
                    currentPoint = location
                    isDrawing = false
                    
                    print("🎨 结束绘制 - 终点: (\(Int(location.x)), \(Int(location.y)))")
                    print("🎨 拖拽事件数: \(dragEventCount)")
                    
                    // 回调通知绘制完成
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.onDrawing?(self.startPoint, self.currentPoint, true)
                    }
                    
                    // 拦截事件
                    return nil
                }
                
            default:
                break
            }
            
            return Unmanaged.passUnretained(event)
        }
    }

    private func isDrawingTriggerPressed(flags: CGEventFlags) -> Bool {
        let requiredModifiers = SettingsManager.shared.drawingTriggerModifiers
        guard !requiredModifiers.isEmpty else { return false }

        let currentModifiers = NSEvent.ModifierFlags(rawValue: UInt(flags.rawValue))
            .intersection(supportedModifierMask)
        return currentModifiers.isSuperset(of: requiredModifiers)
    }

    private func cancelDrawingIfNeeded() {
        guard isDrawing else { return }
        isDrawing = false
        dragEventCount = 0
        DispatchQueue.main.async { [weak self] in
            self?.onDrawingCancelled?()
        }
    }
}
