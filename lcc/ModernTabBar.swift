import SwiftUI

struct ModernTabBar: View {
    let tabs: [String]
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "mountain.2")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)

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
                            .foregroundColor(selectedTab == idx ? .primary : .secondary)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(selectedTab == idx ? Color.accentColor.opacity(0.85) : Color(.systemBackground).opacity(0.9))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(.systemBackground).opacity(0.7))
                .shadow(color: Color.black.opacity(0.08), radius: 6, y: 1)
        )
        .overlay(
            Capsule()
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .padding(.bottom, 24)
        .padding(.horizontal, 32)
        .frame(maxWidth: 420)
        .offset(y: 8)
    }
}

#Preview {
    ModernTabBar(
        tabs: [
            "LCC",
            "BCC",
        ],
        selectedTab: .constant(0)
    )
}
