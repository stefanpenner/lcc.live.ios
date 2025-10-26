import SwiftUI

@available(iOS 26.0, *)
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
                .liquidGlass(
                    tint: isSelected ? Color.accentColor : nil,
                    in: Circle(),
                    isInteractive: true
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(mode.rawValue))
        .accessibilityValue(Text(isSelected ? "Selected" : "Not selected"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

@available(iOS 26.0, *)
struct GridModeToggle: View {
    @Binding var gridMode: PhotoTabView.GridMode

    var body: some View {
        LiquidGlassContainer(spacing: 16.0) {
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
            .liquidGlass(in: RoundedRectangle(cornerRadius: 14))
            .padding([.top, .trailing], 8)
        }
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
