import SwiftUI

struct GalleryFullScreenView: View {
    let items: [MediaItem]
    let initialIndex: Int
    let onClose: () -> Void

    @State private var index: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var dismissOpacity: Double = 1.0
    
    init(items: [MediaItem], initialIndex: Int, onClose: @escaping () -> Void) {
        self.items = items
        self.initialIndex = clampIndex(initialIndex, count: items.count)
        self.onClose = onClose
        _index = State(initialValue: self.initialIndex)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Black background that stays visible even when dragging
                Color.black
                    .ignoresSafeArea(.all)
                    .zIndex(0)
                
                TabView(selection: $index) {
                    ForEach(items.indices, id: \.self) { i in
                        page(for: items[i])
                            .tag(i)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .ignoresSafeArea(edges: .all)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.black)
                .ignoresSafeArea(edges: .all)
                .zIndex(1)
                .disabled(isDragging) // Disable TabView swipe during drag to prevent conflicts
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea(.all))
            .ignoresSafeArea(edges: .all)
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
                            if !isDragging {
                                isDragging = true
                            }
                            // Update drag offset and opacity without animation for smooth dragging
                            // Use transaction to disable animations during drag
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                dragOffset = translation
                                let progress = Double(abs(translation)) / 300.0
                                dismissOpacity = max(0, 1.0 - progress)
                            }
                        }
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        let velocity = value.predictedEndTranslation.height - translation
                        
                        // Close if dragged down enough or fast velocity
                        if translation > 150 || velocity > 500 {
                            // Animate out before closing
                            // Use a large value instead of UIScreen.main.bounds.height for better compatibility
                            let screenHeight: CGFloat = 1000 // Large enough value to animate off screen
                            withAnimation(.easeOut(duration: 0.2)) {
                                dragOffset = screenHeight
                                dismissOpacity = 0
                            }
                            // Close after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onClose()
                            }
                        } else {
                            // Animate back smoothly - reset all state together in a single animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                dragOffset = 0
                                dismissOpacity = 1.0
                                isDragging = false
                            }
                        }
                    }
            )
        }
        .background(Color.black.ignoresSafeArea(.all))
        .ignoresSafeArea(edges: .all)
        .preferredColorScheme(.dark) // Ensure dark mode for consistent black background
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
                            .ignoresSafeArea(.all)
                    case .failure: 
                        Color.black
                            .ignoresSafeArea(.all)
                    case .empty: 
                        ZStack {
                            Color.black
                            ProgressView()
                                .tint(.white)
                        }
                        .ignoresSafeArea(.all)
                    @unknown default: 
                        Color.black
                            .ignoresSafeArea(.all)
                    }
                }
            } else {
                Color.black
                    .ignoresSafeArea(.all)
            }
        case .youtubeVideo(let embedURL):
            YouTubePlayerView(embedURL: embedURL, autoplay: true)
                .ignoresSafeArea(.all)
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
                    .ignoresSafeArea(.all)
                
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .clipped()
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
            .frame(width: geometry.size.width, height: geometry.size.height)
            .ignoresSafeArea(.all)
        }
        .ignoresSafeArea(.all)
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

