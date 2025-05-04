import SwiftUI

struct GridModeToggle: View {
    @Binding var gridMode: PhotoTabView.GridMode
    @Binding var isToggleVisible: Bool
    @Binding var showFloatingButton: Bool
    var toggleAnimation: Animation
    var floatingButtonSize: CGFloat
    var floatingButtonPadding: CGFloat
    var gridIcon: String

    var body: some View {
        VStack {
            HStack {
                Spacer()
                if isToggleVisible {
                    HStack(spacing: 8) {
                        Button(action: { gridMode = .compact }) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(gridMode == .compact ? .accentColor : .secondary)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(gridMode == .compact ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        Button(action: { gridMode = .single }) {
                            Image(systemName: "rectangle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(gridMode == .single ? .accentColor : .secondary)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(gridMode == .single ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground).opacity(0.7))
                            .shadow(radius: 2)
                    )
                    .padding([.top, .trailing], 8)
                    .animation(toggleAnimation, value: isToggleVisible)
                } else if showFloatingButton {
                    Button(action: {
                        withAnimation(toggleAnimation) {
                            isToggleVisible = true
                            showFloatingButton = false
                        }
                    }) {
                        Image(systemName: gridIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.accentColor)
                            .frame(width: floatingButtonSize, height: floatingButtonSize)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground).opacity(0.85))
                                    .shadow(radius: 2)
                            )
                    }
                    .padding([.top, .trailing], floatingButtonPadding)
                    .transition(.opacity)
                    .animation(toggleAnimation, value: showFloatingButton)
                }
            }
            Spacer()
        }
        .allowsHitTesting(true)
    }
} 