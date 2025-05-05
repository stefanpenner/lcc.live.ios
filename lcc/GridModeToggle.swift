import SwiftUI

private struct ToggleButton: View {
    var mode: PhotoTabView.GridMode
    @Binding var currentMode: PhotoTabView.GridMode
    var systemName: String
    var action: () -> Void
    var body: some View {
        Button(action: {
            #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(mode == currentMode ? .accentColor : .secondary)
                .padding(6)
                .background(
                    Circle()
                        .fill(mode == currentMode ? Color.accentColor.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

struct GridModeToggle: View {
    @Binding var gridMode: PhotoTabView.GridMode

    var toggleAnimation: Animation
    var floatingButtonSize: CGFloat
    var floatingButtonPadding: CGFloat
    var gridIcon: String

    var body: some View {
        HStack(spacing: 8) {
            ToggleButton(
                mode: .compact,
                currentMode: $gridMode,
                systemName: "square.grid.2x2",
                action: {
                    print("compact")
                    gridMode = .compact
                }
            )

            ToggleButton(
                mode: .single,
                currentMode: $gridMode,
                systemName: "rectangle.fill",
                action: {
                    print("single")
                    gridMode = .single
                }
            )
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.7))
                .shadow(radius: 2)
        )
        .padding([.top, .trailing], 8)
    }
}
