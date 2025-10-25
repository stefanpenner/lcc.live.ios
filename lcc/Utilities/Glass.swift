import SwiftUI

// Type-erased Shape so we can pass shapes through a single API
struct AnyShape: Shape {
    private let pathBuilder: @Sendable (CGRect) -> Path
    init<S: Shape>(_ shape: S) { self.pathBuilder = { rect in shape.path(in: rect) } }
    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
}

/// Reusable Liquid Glass background aligned with Apple's guidance
/// - Uses system `Material` for blur
/// - Adds subtle refraction and luminous edge
/// - Respects Reduce Transparency accessibility setting
private struct GlassBackgroundView: View {
    let shape: AnyShape
    let material: Material
    let tint: Color?
    let edgeColor: Color?
    let strokeOpacity: Double
    let shadowOpacity: Double

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            if reduceTransparency {
                // Solid fallback for users who reduce transparency
                shape
                    .fill(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.6 : 0.9))
            } else {
                shape.fill(material)
            }

            // Refraction highlight (subtle gradient)
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12),
                            (tint ?? Color.white).opacity(colorScheme == .dark ? 0.03 : 0.06),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(reduceTransparency ? 0.0 : 1.0)

            // Optional tint wash for brand/status emphasis
            if let tint = tint, !reduceTransparency {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.20),
                                tint.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Luminous edge to define elevation
            shape
                .stroke(
                    LinearGradient(
                        colors: [
                            (edgeColor ?? Color.white).opacity(0.30),
                            (edgeColor ?? Color.white).opacity(strokeOpacity * 0.4),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .opacity(reduceTransparency ? 0.2 : 1.0)
        }
        .compositingGroup()
        .shadow(color: Color.black.opacity(shadowOpacity), radius: 10, y: 4)
    }
}

extension View {
    /// Apply a reusable liquid-glass background to this view.
    /// - Parameters:
    ///   - shape: The shape to render (e.g., `Capsule()`, `RoundedRectangle(cornerRadius:)`, `Circle()`).
    ///   - material: System blur material to use. Prefer `.ultraThinMaterial` or `.thinMaterial`.
    ///   - tint: Optional brand/status tint that softly colors the refraction.
    ///   - edgeColor: Optional color for the luminous edge. Defaults to white.
    ///   - strokeOpacity: Opacity multiplier for the edge stroke.
    ///   - shadowOpacity: Opacity of the elevation shadow.
    func glassBackground<S: Shape>(
        _ shape: S,
        material: Material = .ultraThinMaterial,
        tint: Color? = nil,
        edgeColor: Color? = nil,
        strokeOpacity: Double = 0.25,
        shadowOpacity: Double = 0.12
    ) -> some View {
        background(
            GlassBackgroundView(
                shape: AnyShape(shape),
                material: material,
                tint: tint,
                edgeColor: edgeColor,
                strokeOpacity: strokeOpacity,
                shadowOpacity: shadowOpacity
            )
        )
    }
}


