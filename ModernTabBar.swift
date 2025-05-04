import SwiftUI

struct ModernTabBar: View {
    @State private var selectedTab = 0

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<4) { idx in
                Button(action: {
                    selectedTab = idx
                }) {
                    Text("Tab \(idx + 1)")
                        .font(selectedTab == idx ? .system(size: 17, weight: .bold) : .caption)
                        .foregroundColor(selectedTab == idx ? .white : .secondary)
                        .shadow(color: selectedTab == idx ? Color.black.opacity(0.35) : .clear, radius: 2, y: 1)
                        .textCase(.uppercase)
                        .kerning(selectedTab == idx ? 1.2 : 0.2)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(selectedTab == idx ? Color.accentColor : Color(.systemBackground).opacity(0.9))
                )
            }
        }
    }
}

struct ModernTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ModernTabBar()
    }
} 