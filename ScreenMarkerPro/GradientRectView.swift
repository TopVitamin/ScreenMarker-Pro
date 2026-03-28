//
//  GradientRectView.swift
//  ScreenMarkerPro
//
//  Created on 2026-02-05.
//

import Cocoa

/// 渐变矩形边框视图，使用Core Animation实现
class GradientRectView: NSView {
    
    /// 是否为临时矩形（拖拽中的矩形）
    var isTemporary: Bool = false
    
    /// 渐变色配置
    enum GradientStyle {
        case laserBlue      // 激光蓝→霓虹紫（默认）
        case neonGreen      // 霓虹绿→天蓝
        case hotPink        // 热粉→橙红
        
        var colors: [CGColor] {
            switch self {
            case .laserBlue:
                return [
                    NSColor(calibratedRed: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor,  // 激光蓝
                    NSColor(calibratedRed: 0.8, green: 0.0, blue: 1.0, alpha: 1.0).cgColor   // 霓虹紫
                ]
            case .neonGreen:
                return [
                    NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.5, alpha: 1.0).cgColor,  // 霓虹绿
                    NSColor(calibratedRed: 0.0, green: 0.7, blue: 1.0, alpha: 1.0).cgColor   // 天蓝
                ]
            case .hotPink:
                return [
                    NSColor(calibratedRed: 1.0, green: 0.2, blue: 0.6, alpha: 1.0).cgColor,  // 热粉
                    NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.0, alpha: 1.0).cgColor   // 橙红
                ]
            }
        }
    }
    
    private var gradientLayer: CAGradientLayer?
    private var shapeLayer: CAShapeLayer?
    
    // 从SettingsManager获取配置
    private var settings: SettingsManager { SettingsManager.shared }
    
    private let gradientStyle: GradientStyle = .laserBlue
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        self.wantsLayer = true
        self.layer?.backgroundColor = nil
        
        // 1. 创建渐变层 (Gradient Layer)
        // 如果是单色模式，我们仍然使用GradientLayer作为容器，但可能不显示渐变，
        // 或者简单点：始终使用GradientLayer作为Mask基底，
        // 如果是单色模式，我们直接设置ShapeLayer的颜色而不使用Mask？
        // 不，GradientLayer作为Mask是实现渐变边框的关键。
        // 如果要实现"单色边框"，其实不需要GradientLayer，直接ShapeLayer即可。
        // 但为了代码统一，我们可以：
        //   - 渐变模式：ShapeLayer (White) -> Mask for GradientLayer (Gradient Colors)
        //   - 单色模式：ShapeLayer (Solid Color) -> 不需要GradientLayer (或者GradientLayer设为纯色)
        
        // 读取设置
        let mode = settings.borderColorMode
        let lineWidth = settings.lineWidth
        let radius = settings.cornerRadius
        let lineStyle = settings.lineStyle
        
        if mode == .randomGradient {
            // --- 渐变模式 ---
            
            let gradient = CAGradientLayer()
            gradient.frame = bounds
            
            // 随机选择一个渐变风格 (简单起见，这里先随机)
            // 实际需求说是"随机渐变"，每次不同。
            // 我们可以扩充GradientStyle或随机生成颜色。
            // 为了MVP，我们从预设中随机选一个
            let randomStyle = [GradientStyle.laserBlue, .neonGreen, .hotPink].randomElement() ?? gradientStyle
            gradient.colors = randomStyle.colors
            
            gradient.startPoint = CGPoint(x: 0, y: 1)
            gradient.endPoint = CGPoint(x: 1, y: 0)
            
            let shape = CAShapeLayer()
            let insetRect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            let path = CGPath(roundedRect: insetRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
            
            shape.path = path
            shape.fillColor = .clear
            shape.strokeColor = NSColor.white.cgColor // Mask需要白色让其显示
            shape.lineWidth = lineWidth
            
            // 虚线设置
            if lineStyle == .dashed {
                // [线长, 间隙]
                shape.lineDashPattern = [NSNumber(value: lineWidth * 3), NSNumber(value: lineWidth * 1.5)]
            }
            
            gradient.mask = shape
            self.layer?.addSublayer(gradient)
            
            self.gradientLayer = gradient
            self.shapeLayer = shape
            
        } else {
            // --- 单色模式 ---
            
            // 不需要GradientLayer，直接添加ShapeLayer
            let shape = CAShapeLayer()
            let insetRect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            let path = CGPath(roundedRect: insetRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
            
            shape.path = path
            shape.fillColor = .clear
            shape.strokeColor = settings.nsSingleColor.cgColor
            shape.lineWidth = lineWidth
            
            // 虚线设置
            if lineStyle == .dashed {
                shape.lineDashPattern = [NSNumber(value: lineWidth * 3), NSNumber(value: lineWidth * 1.5)]
            }
            
            self.layer?.addSublayer(shape)
            self.shapeLayer = shape
        }
    }
    
    override func layout() {
        super.layout()
        
        // 更新布局时需要重新计算路径
        // 因为涉及模式变化（如从Gradient变Single），layout更新比较复杂。
        // 简单处理：如果是resize，我们更新path。
        // 如果是模式变化，其实应该是重建view（因为我们是在DrawingManager创建时读取的设置）。
        // 矩形创建后，其样式通常固定（不随设置实时变，除非需求要求实时变）。
        // 需求："用户可实时调整标记框的样式，参数需即时生效" -> 通常指新画的框，或者所有框？
        // V0.02需求："参数需即时生效"。通常为了性能，只影响新画的框即可。如果需要影响旧的，需要监听Settings变化。
        // 为简化V0.02，我们假设只影响新画的框。这也是合理体验。
        
        let lineWidth = settings.lineWidth
        let radius = settings.cornerRadius
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        gradientLayer?.frame = bounds
        
        let insetRect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = CGPath(roundedRect: insetRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        shapeLayer?.path = path
        
        CATransaction.commit()
    }
}
