import SwiftUI

struct ModernTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @Binding var showConnectionDetails: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Left: App icon
            Image(systemName: "mountain.2")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            // Center: Tab buttons
            HStack(spacing: 8) {
                ForEach(0 ..< tabs.count, id: \.self) { idx in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = idx
                            #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                    }) {
                    HStack(spacing: 6) {
                        Text(tabs[idx].uppercased())
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(
                                selectedTab == idx 
                                    ? AnyShapeStyle(.primary)
                                    : AnyShapeStyle(.secondary)
                            )
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .background(
                        ZStack {
                            if selectedTab == idx {
                                // Active: Liquid Glass with accent vibrancy
                                Capsule()
                                    .fill(.thinMaterial)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.accentColor.opacity(0.5),
                                                Color.accentColor.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                // Luminous edge
                                Capsule()
                                    .stroke(Color.accentColor.opacity(0.4), lineWidth: 1.5)
                            } else {
                                // Inactive: Subtle glass
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                            }
                        }
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Right: Connection status
            ConnectionStatusView(showDetails: $showConnectionDetails)
                .scaleEffect(0.85) // Make it slightly smaller to fit
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            ZStack {
                // Liquid Glass: Ultra-thin material with depth
                Capsule()
                    .fill(.ultraThinMaterial)
                
                // Refraction effect: Subtle gradient overlay
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Reflection highlight
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.15), radius: 12, y: 4)
        )
        .padding(.bottom, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: 480)
        .offset(y: 8)
    }
}

#Preview {
    ModernTabBar(
        tabs: [
            "LCC",
            "BCC",
        ],
        selectedTab: .constant(0),
        showConnectionDetails: .constant(false)
    )
    .environmentObject(NetworkMonitor.shared)
}
