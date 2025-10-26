import SwiftUI

// MARK: - iOS 26+ Native Liquid Glass Support Only

// Type-erased Shape so we can pass shapes through a single API
struct AnyShape: Shape {
    private let pathBuilder: @Sendable (CGRect) -> Path
    init<S: Shape>(_ shape: S) { self.pathBuilder = { rect in shape.path(in: rect) } }
    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
}

// MARK: - Glass Container for Multiple Effects

/// Container that enables Liquid Glass effects to merge and morph when close together
/// Uses native GlassEffectContainer for iOS 26+
@available(iOS 26.0, *)
struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 40.0, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            content
        }
    }
}

// MARK: - Enhanced Glass Button Style

@available(iOS 26.0, *)
struct LiquidGlassButtonStyle: ButtonStyle {
    let tint: Color?
    let shape: AnyShape
    
    init<S: Shape>(tint: Color? = nil, shape: S = Capsule() as! S) {
        self.tint = tint
        self.shape = AnyShape(shape)
    }
    
    // Convenience initializer for default Capsule shape
    init(tint: Color? = nil) {
        self.tint = tint
        self.shape = AnyShape(Capsule())
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.glass)
    }
}

// MARK: - View Extensions

@available(iOS 26.0, *)
extension View {
    /// Apply native Liquid Glass effect (iOS 26+ only)
    /// - Parameters:
    ///   - tint: Optional tint color for prominence
    ///   - shape: Shape for the glass effect
    ///   - isInteractive: Whether the glass should respond to interactions
    ///   - isEnabled: Whether the effect is enabled
    func liquidGlass<S: Shape>(
        tint: Color? = nil,
        in shape: S = Capsule(),
        isInteractive: Bool = false,
        isEnabled: Bool = true
    ) -> some View {
        if isEnabled {
            let glass = Glass.regular
                .tint(tint ?? .clear)
                .interactive(isInteractive)
            
            return AnyView(
                self.glassEffect(glass, in: shape)
            )
        } else {
            return AnyView(self)
        }
    }

    // Compat shim for previous custom blur API; now maps to native iOS 26-only glass
    @available(iOS 26.0, *)
    func glassBackground<S: Shape>(
        _ shape: S,
        material: Material = .ultraThinMaterial,
        tint: Color? = nil,
        edgeColor: Color? = nil,
        strokeOpacity: Double = 0.25,
        shadowOpacity: Double = 0.12,
        isInteractive: Bool = false
    ) -> some View {
        let _ = (material, edgeColor, strokeOpacity, shadowOpacity) // kept for signature compatibility
        return self.liquidGlass(tint: tint, in: shape, isInteractive: isInteractive, isEnabled: true)
    }
}

// MARK: - Button Style Extensions

@available(iOS 26.0, *)
extension ButtonStyle where Self == LiquidGlassButtonStyle {
    /// Liquid Glass button style using native iOS 26+ APIs
    static func liquidGlass(tint: Color? = nil) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(tint: tint)
    }
    
    /// Liquid Glass button style with custom shape
    static func liquidGlass<S: Shape>(tint: Color? = nil, shape: S) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(tint: tint, shape: shape)
    }
    
    /// Prominent Liquid Glass button style for important actions
    static var liquidGlassProminent: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(tint: .accentColor)
    }
}