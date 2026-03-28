import Cocoa

/// 绘制管理器 - 负责创建、更新和销毁矩形标记
class DrawingManager {
    // MARK: - Properties
    
    private var overlayWindows: [OverlayWindow] = []
    private var activeRectViews: [GradientRectView] = []
    
    /// 计时器字典：为每个rectView管理独立的定时器
    private var timers: [ObjectIdentifier: DispatchWorkItem] = [:]
    

    
    /// 动画配置
    private let fadeDuration: TimeInterval = 0.5     // 淡出时长
    
    /// 最大框数量限制 (User Request: 10 per screen/total)
    /// 简单起见，我们控制总数
    private let maxRectCount: Int = 10
    
    // MARK: - Lifecycle
    
    init(overlayWindows: [OverlayWindow]) {
        self.overlayWindows = overlayWindows
    }
    
    deinit {
        // 清理所有计时器
        cancelAllTimers()
    }
    
    // MARK: - Public Methods
    
    func updateOverlayWindows(_ windows: [OverlayWindow]) {
        clearAll()
        self.overlayWindows = windows
    }
    
    /// 开始绘制新矩形
    /// - Parameters:
    ///   - startPoint: 起点坐标（屏幕坐标系）
    ///   - endPoint: 终点坐标（屏幕坐标系）
    func updateDrawing(from startPoint: NSPoint, to endPoint: NSPoint, isFinished: Bool) {
        // 输入点已经是Cocoa全局坐标(左下角原点)
        guard let targetWindow = overlayWindows.first(where: { NSPointInRect(startPoint, $0.frame) }),
              let contentView = targetWindow.contentView else {
            cancelCurrentDrawing()
            return
        }
        
        // 2. 计算在目标窗口内的局部坐标
        let rect = calculateRect(from: startPoint, to: endPoint, in: targetWindow)
        
        // 过滤太小的矩形（避免误触）
        guard rect.width > 5 && rect.height > 5 else {
            cancelCurrentDrawing()
            return
        }
        
        if isFinished {
            // 绘制完成：创建最终矩形并启动消失动画
            createFinalRect(rect: rect, in: contentView)
        } else {
            // 绘制中：实时更新临时矩形
            updateTemporaryRect(rect: rect, in: contentView)
        }
    }
    
    /// 清除所有矩形
    func clearAll() {
        cancelAllTimers()
        activeRectViews.forEach { $0.removeFromSuperview() }
        activeRectViews.removeAll()
    }

    func cancelCurrentDrawing() {
        removeTemporaryRectIfNeeded()
    }
    
    // MARK: - Private Methods
    
    /// 计算矩形区域（将全局屏幕坐标转换为目标窗口局部坐标）
    private func calculateRect(from start: NSPoint, to end: NSPoint, in window: NSWindow) -> NSRect {
        // window.convertPoint(fromScreen:)会按目标窗口所在屏幕正确处理多屏偏移和负坐标
        let startWindowPoint = window.convertPoint(fromScreen: start)
        let endWindowPoint = window.convertPoint(fromScreen: end)
        
        return NSRect(from: startWindowPoint, to: endWindowPoint)
    }
    
    /// 更新临时矩形（拖拽中）
    private func updateTemporaryRect(rect: NSRect, in contentView: NSView) {
        // 优化：尝试复用当前的临时矩形，而不是每次都销毁重建
        if let lastView = activeRectViews.last, lastView.isTemporary {
            // 复用现有视图，仅更新frame
            lastView.frame = rect
        } else {
            // 没有临时矩形，创建新的
            let rectView = GradientRectView(frame: rect)
            rectView.isTemporary = true
            contentView.addSubview(rectView)
            activeRectViews.append(rectView)
        }
    }
    
    /// 创建最终矩形（绘制完成）
    private func createFinalRect(rect: NSRect, in contentView: NSView) {
        // 移除临时矩形
        removeTemporaryRectIfNeeded()
        
        // 检查数量限制：如果超过10个，移除最早的一个
        while activeRectViews.count >= maxRectCount {
            if let firstView = activeRectViews.first {
                removeRectView(firstView)
            }
        }
        
        // 创建最终矩形
        let rectView = GradientRectView(frame: rect)
        rectView.isTemporary = false
        
        contentView.addSubview(rectView)
        activeRectViews.append(rectView)
        
        // 强制刷新并显示
        if let window = contentView.window {
            window.orderFrontRegardless()
            rectView.needsDisplay = true
        }
        
        // 启动消失动画 (时长从Settings读取)
        let duration = SettingsManager.shared.duration
        startDismissAnimation(for: rectView, duration: duration)
    }
    
    /// 移除指定的RectView并清理资源
    private func removeRectView(_ view: GradientRectView) {
        cancelTimer(for: view)
        view.removeFromSuperview()
        if let index = activeRectViews.firstIndex(of: view) {
            activeRectViews.remove(at: index)
        }
    }

    private func removeTemporaryRectIfNeeded() {
        guard let tempIndex = activeRectViews.lastIndex(where: { $0.isTemporary }) else { return }
        let tempView = activeRectViews[tempIndex]
        cancelTimer(for: tempView)
        tempView.removeFromSuperview()
        activeRectViews.remove(at: tempIndex)
    }
    
    /// 启动消失动画（使用DispatchWorkItem管理计时器）
    private func startDismissAnimation(for rectView: GradientRectView, duration: TimeInterval) {
        let viewId = ObjectIdentifier(rectView)
        
        // 如果该view已经有计时器，先取消
        cancelTimer(for: rectView)
        
        // 创建新的计时器任务
        let workItem = DispatchWorkItem(block: { [weak self, weak rectView] in
            guard let self = self, let rectView = rectView else { return }
            
            // 淡出动画
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = self.fadeDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                rectView.animator().alphaValue = 0.0
            }, completionHandler: { [weak self, weak rectView] in
                guard let self = self, let rectView = rectView else { return }
                
                self.removeRectView(rectView)
            })
        })
        
        // 保存计时器引用
        timers[viewId] = workItem
        
        // 延迟执行
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
    
    /// 取消指定view的计时器
    private func cancelTimer(for view: GradientRectView) {
        let viewId = ObjectIdentifier(view)
        if let workItem = timers[viewId] {
            workItem.cancel()
            timers.removeValue(forKey: viewId)
        }
    }
    
    /// 取消所有计时器
    private func cancelAllTimers() {
        timers.values.forEach { $0.cancel() }
        timers.removeAll()
    }
}

// MARK: - NSRect Extension

extension NSRect {
    init(from p1: NSPoint, to p2: NSPoint) {
        let minX = min(p1.x, p2.x)
        let minY = min(p1.y, p2.y)
        let maxX = max(p1.x, p2.x)
        let maxY = max(p1.y, p2.y)
        self.init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
