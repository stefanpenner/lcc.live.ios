import SwiftUI

struct GalleryFullScreenView: View {
    let items: [MediaItem]
    let initialIndex: Int
    let onClose: () -> Void

    @State private var index: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    init(items: [MediaItem], initialIndex: Int, onClose: @escaping () -> Void) {
        self.items = items
        self.initialIndex = clampIndex(initialIndex, count: items.count)
        self.onClose = onClose
        _index = State(initialValue: self.initialIndex)
    }
    
    private var dismissOpacity: Double {
        if isDragging {
            let progress = Double(abs(dragOffset)) / 300.0
            return max(0, 1.0 - progress)
        }
        return 1.0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea(.all)
                
                TabView(selection: $index) {
                    ForEach(items.indices, id: \.self) { i in
                        page(for: items[i])
                            .tag(i)
                            .background(Color.black)
                            .ignoresSafeArea(edges: .all)
                    }
                }
                .tabViewStyle(.page)
                .background(Color.black)
                .ignoresSafeArea(edges: .all)
            }
            .background(Color.black.ignoresSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", action: onClose)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = galleryShareURL(for: currentItem) {
                        ShareLink(item: url) { 
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .offset(y: dragOffset)
            .opacity(dismissOpacity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        let translation = value.translation.height
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(translation)
                        
                        // Only allow downward drags that are more vertical than horizontal
                        if translation > 0 && vertical > horizontal {
                            isDragging = true
                            dragOffset = translation
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        let velocity = value.predictedEndTranslation.height - translation
                        
                        // Close if dragged down enough or fast velocity
                        if translation > 150 || velocity > 500 {
                            onClose()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                                isDragging = false
                            }
                        }
                    }
            )
        }
        .background(Color.black.ignoresSafeArea(.all))
        .ignoresSafeArea(edges: .all)
    }

    @ViewBuilder
    private func page(for media: MediaItem) -> some View {
        switch media.type {
        case .image:
            if let url = URL(string: media.url) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): 
                        ZoomableImageView(image: image)
                    case .failure: Color.black
                    case .empty: 
                        ZStack {
                            Color.black
                            ProgressView()
                                .tint(.white)
                        }
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

struct ZoomableImageView: View {
    let image: Image
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            let newScale = scale * delta
                            scale = min(max(newScale, 1.0), 4.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                withAnimation(.spring(response: 0.3)) {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    // Double-tap always resets zoom to normal
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: scale > 1.0 ? 0 : 30)
                        .onChanged { value in
                            guard scale > 1.0 else { return }
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            offset = limitOffset(newOffset, geometry: geometry)
                        }
                        .onEnded { _ in
                            guard scale > 1.0 else { return }
                            lastOffset = offset
                        }
                )
            }
        }
    }
    
    private func limitOffset(_ offset: CGSize, geometry: GeometryProxy) -> CGSize {
        let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
        let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
        
        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }
}

