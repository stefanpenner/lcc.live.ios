import SwiftUI

struct ModernTabBar: View {
    let tabs: [(title: String, icon: String)]
    @Binding var selectedTab: Int
    var isAnyFullScreen: Bool
    var barHeight: CGFloat = 36
    var barHorizontalPadding: CGFloat = 8

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
                Button(action: {
                    selectedTab = idx
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(tab.title.uppercased())
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedTab == idx ? .primary : .secondary)
                    }
                    .shadow(color: selectedTab == idx ? Color.black.opacity(0.35) : .clear, radius: 2, y: 1)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(selectedTab == idx ? Color.accentColor.opacity(0.18) : Color.clear)
                )
            }
        }
        .frame(height: barHeight)
        .padding(.horizontal, barHorizontalPadding)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
    }
}

struct ModernTabBar_Previews: PreviewProvider {
    @State static var selectedTab = 0
    static var previews: some View {
        ZStack {
            Color(.systemBackground)
            ModernTabBar(
                tabs: [("lcc", "mountain.2"), ("bcc", "mountain.2")],
                selectedTab: $selectedTab,
                isAnyFullScreen: false
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}
