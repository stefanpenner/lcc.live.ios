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
                    .glassBackground(
                        Capsule(),
                        material: selectedTab == idx ? .thinMaterial : .ultraThinMaterial,
                        tint: selectedTab == idx ? Color.accentColor : nil,
                        edgeColor: selectedTab == idx ? Color.accentColor : nil,
                        strokeOpacity: selectedTab == idx ? 0.45 : 0.20,
                        shadowOpacity: selectedTab == idx ? 0.16 : 0.10
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
        .glassBackground(Capsule(), material: .ultraThinMaterial)
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
