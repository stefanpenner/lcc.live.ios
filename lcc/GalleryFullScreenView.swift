import SwiftUI

@available(iOS 26.0, *)
struct GalleryFullScreenView: View {
    let items: [MediaItem]
    let initialIndex: Int
    let onClose: () -> Void

    @State private var index: Int

    init(items: [MediaItem], initialIndex: Int, onClose: @escaping () -> Void) {
        self.items = items
        self.initialIndex = clampIndex(initialIndex, count: items.count)
        self.onClose = onClose
        _index = State(initialValue: self.initialIndex)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $index) {
                ForEach(items.indices, id: \.self) { i in
                    page(for: items[i])
                        .tag(i)
                        .background(Color.black)
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", action: onClose)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = galleryShareURL(for: currentItem) {
                        ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func page(for media: MediaItem) -> some View {
        switch media.type {
        case .image:
            if let url = URL(string: media.url) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit()
                    case .failure: Color.black
                    case .empty: ProgressView()
                    @unknown default: Color.black
                    }
                }
            } else {
                Color.black
            }
        case .youtubeVideo(let embedURL):
            YouTubePlayerView(embedURL: embedURL, autoplay: true)
        }
    }

    private var currentItem: MediaItem? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }

    // share URL moved to helper
}

