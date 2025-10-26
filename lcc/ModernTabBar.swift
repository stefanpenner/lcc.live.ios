import SwiftUI

@available(iOS 26.0, *)
struct UnifiedBottomBarToolbar: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @Binding var gridMode: PhotoTabView.GridMode
    @Binding var showConnectionDetails: Bool

    var body: some View {
        HStack {
            Picker("", selection: $selectedTab) {
                Text("LCC").tag(0)
                Text("BCC").tag(1)
            }
            .pickerStyle(.segmented)

            Picker("", selection: $gridMode) {
                Image(systemName: "square.grid.2x2").tag(PhotoTabView.GridMode.compact)
                Image(systemName: "rectangle.fill").tag(PhotoTabView.GridMode.single)
            }
            .pickerStyle(.segmented)

            ConnectionStatusView(showDetails: $showConnectionDetails)
        }
    }
}

@available(iOS 26.0, *)
struct UnifiedBottomBar: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @Binding var gridMode: PhotoTabView.GridMode
    @Binding var showConnectionDetails: Bool

    var body: some View {
        LiquidGlassContainer(spacing: 16.0) {
            HStack(spacing: 12) {
                // Left: Segmented tab picker (drag between items)
                Picker("", selection: $selectedTab) {
                    ForEach(0 ..< tabs.count, id: \.self) { idx in
                        Text(tabs[idx].uppercased()).tag(idx)
                    }
                }
                .pickerStyle(.segmented)

                // Separator between sections
                Divider()
                    .frame(height: 28)
                    .overlay(Color.primary.opacity(0.15))

                // Right: Segmented grid/list picker + connection status
                Picker("", selection: $gridMode) {
                    Image(systemName: "square.grid.2x2").tag(PhotoTabView.GridMode.compact)
                    Image(systemName: "rectangle.fill").tag(PhotoTabView.GridMode.single)
                }
                .pickerStyle(.segmented)

                ConnectionStatusView(showDetails: $showConnectionDetails)
                    .scaleEffect(0.9)
            }
            .liquidGlass(in: Capsule(), isInteractive: false)
        }
    }
}

#Preview {
    UnifiedBottomBar(
        tabs: ["LCC", "BCC"],
        selectedTab: .constant(0),
        gridMode: .constant(.compact),
        showConnectionDetails: .constant(false)
    )
    .environmentObject(NetworkMonitor.shared)
}
