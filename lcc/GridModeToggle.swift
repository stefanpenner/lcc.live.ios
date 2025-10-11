import SwiftUI

private struct ToggleButton: View {
    var mode: PhotoTabView.GridMode
    @Binding var currentMode: PhotoTabView.GridMode
    var systemName: String
    var action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var isSelected: Bool { mode == currentMode }

    var body: some View {
        Button(action: {
            #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        if isSelected {
                            // Active: Liquid Glass with accent glow
                            Circle()
                                .fill(.thinMaterial)
                            
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.accentColor.opacity(0.4),
                                            Color.accentColor.opacity(0.2),
                                            Color.accentColor.opacity(0.05)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 22
                                    )
                                )
                            
                            Circle()
                                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1.5)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 6, y: 2)
                        }
                    }
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(mode.rawValue))
        .accessibilityValue(Text(isSelected ? "Selected" : "Not selected"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct GridModeToggle: View {
    @Binding var gridMode: PhotoTabView.GridMode

    var body: some View {
        HStack(spacing: 8) {
            ToggleButton(
                mode: .compact,
                currentMode: $gridMode,
                systemName: "square.grid.2x2",
                action: {
                    gridMode = .compact
                }
            )

            ToggleButton(
                mode: .single,
                currentMode: $gridMode,
                systemName: "rectangle.fill",
                action: {
                    gridMode = .single
                }
            )
        }
        .padding(8)
        .background(
            ZStack {
                // Liquid Glass container
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                
                // Refraction gradient
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Luminous edge
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
        )
        .padding([.top, .trailing], 8)
    }
}

struct GridModeTogglePreview : View {
    @State private var gridMode: PhotoTabView.GridMode = .compact

    var body : some View {
        GridModeToggle(gridMode: $gridMode)
    }
}

#Preview {
    GridModeTogglePreview()
}
