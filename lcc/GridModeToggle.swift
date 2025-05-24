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
                    Group {
                        if isSelected {
                            Circle()
                                .fill(Color.accentColor.opacity(0.18))
                                .shadow(color: Color.accentColor.opacity(0.18), radius: 4, y: 1)
                        } else {
                            Color.clear
                        }
                    }
                )
                .animation(.easeInOut(duration: 0.18), value: isSelected)
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

struct GridModeTogglePreview : View {
    @State private var gridMode: PhotoTabView.GridMode = .compact

    var body : some View {
        GridModeToggle(gridMode: $gridMode)
    }
}

#Preview {
    GridModeTogglePreview()
}
