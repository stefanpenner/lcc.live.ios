import Combine
import Foundation
import SwiftUI

struct PhotoTabView: View {
    let mediaItems: [MediaItem]
    
    @Binding public var gridMode: GridMode
    var onRequestFullScreen: (PresentedMedia) -> Void
    @EnvironmentObject var preloader: ImagePreloader
    @EnvironmentObject var apiService: APIService

    @Environment(\.colorScheme) var colorScheme
    @State private var isRefreshing = false
    @State private var hasCompletedInitialLoad = false
    @State private var isCompletingLoad = false // Prevent multiple completion triggers
    @State private var hasReceivedInitialPayload = false // Track if API has responded
    
    private let logger = Logger(category: .ui)

    // User grid mode
    public enum GridMode: String, CaseIterable, Identifiable {
        case compact = "Compact"
        case single = "Single"
        var id: String { rawValue }
    }

    private let spacing: CGFloat = 2 // Minimal spacing for edge-to-edge feel

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let columns = gridMode == .single ? 1 : max(1, Int(availableWidth / 180))
            let imageWidth = (availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            let imageHeight = imageWidth * (gridMode == .single ? 0.9 : 0.9)
            let gridItems = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: columns)
            
            ZStack {
                // Main content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            if mediaItems.isEmpty {
                                // Only show empty state after we've received API response
                                if hasReceivedInitialPayload {
                                    EmptyStateView()
                                        .frame(width: availableWidth, height: availableHeight * 0.6)
                                }
                            } else {
                                LazyVGrid(columns: gridItems, spacing: spacing) {
                                    ForEach(mediaItems, id: \.id) { mediaItem in
                                        MediaCell(
                                            mediaItem: mediaItem,
                                            imageWidth: imageWidth,
                                            imageHeight: imageHeight,
                                            colorScheme: colorScheme,
                                            hasCompletedInitialLoad: hasCompletedInitialLoad,
                                            onTap: {
                                                onRequestFullScreen(PresentedMedia(mediaItem: mediaItem))
                                            },
                                            onRetry: {
                                                if !mediaItem.type.isVideo, let url = URL(string: mediaItem.url) {
                                                    preloader.retryImage(for: url)
                                                }
                                            }
                                        )
                                    }
                                    
                                    // Bottom spacer for grid mode toggle
                                    Color.clear
                                        .frame(height: 70)
                                        .gridCellColumns(columns)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(minHeight: availableHeight)
                }
                .refreshable {
                    await performRefresh()
                }
                .scrollContentBackground(.hidden)
                .background(ScrollViewConfigurator())
                .ignoresSafeArea(edges: .all)
                .modifier(ZeroScrollContentMarginsIfAvailable())
                
                // Unified loading overlay during initial load
                if !hasCompletedInitialLoad && !mediaItems.isEmpty {
                    VStack(spacing: 0) {
                        InitialLoadingView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                }

                // Fades pinned to device edges using overlay alignment so they reach the very top/bottom
                Color.clear
                    .overlay(alignment: .top) {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.7), location: 0.0),
                                .init(color: Color.black.opacity(0.35), location: 0.22),
                                .init(color: Color.clear, location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 140)
                        .ignoresSafeArea(edges: .top)
                    }
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.clear, location: 0.0),
                                .init(color: Color.black.opacity(0.4), location: 0.88),
                                .init(color: Color.black.opacity(0.9), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 220)
                        .ignoresSafeArea(edges: .bottom)
                        .offset(y: 60) // start further offscreen for seamless fade
                    }
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(edges: .all)
        }
        .onAppear {
            logger.info("📱 PhotoTabView appeared with \(mediaItems.count) media items")
            logger.debug("Initial state - hasReceivedPayload: \(hasReceivedInitialPayload), hasCompletedLoad: \(hasCompletedInitialLoad)")
            
            preloader.preloadMedia(from: mediaItems)
            preloader.refreshImages()
            
            // Check completion status periodically
            Task { @MainActor in
                for iteration in 0..<50 { // Check every 100ms for up to 5 seconds
                    try? await Task.sleep(for: .milliseconds(100))
                    checkInitialLoadCompletion()
                    if hasCompletedInitialLoad {
                        logger.info("✅ Initial load completed at iteration \(iteration)")
                        break
                    }
                }
                
                // Safety timeout: mark initial load as complete after 5 seconds regardless
                if !hasCompletedInitialLoad {
                    logger.warning("⏱️ Safety timeout triggered - forcing initial load completion")
                    withAnimation(.easeOut(duration: 0.4)) {
                        hasCompletedInitialLoad = true
                    }
                }
            }
        }
        .onChange(of: preloader.loadedImages.count) { _, _ in
            checkInitialLoadCompletion()
        }
        .onChange(of: preloader.loading.count) { _, _ in
            checkInitialLoadCompletion()
        }
        .onChange(of: mediaItems.isEmpty) { _, isEmpty in
            logger.debug("📊 Media items empty changed: \(isEmpty)")
            
            // Mark that we've received API payload once we have items
            if !isEmpty && !hasReceivedInitialPayload {
                logger.info("📦 Received API payload with \(mediaItems.count) items")
                hasReceivedInitialPayload = true
            }
        }
        .onChange(of: apiService.isLoading) { _, isLoading in
            logger.debug("🔄 API loading state changed: \(isLoading)")
            
            // Mark payload received when API completes (whether we have items or not)
            if !isLoading && !hasReceivedInitialPayload {
                logger.info("📦 API loading completed - mediaItems: \(mediaItems.count)")
                hasReceivedInitialPayload = true
                
                // If API loading completes with no images, mark initial load as done
                if mediaItems.isEmpty {
                    logger.info("⚠️ No media items after API load - completing initial load")
                    hasCompletedInitialLoad = true
                }
            }
        }
    }
    
    private func checkInitialLoadCompletion() {
        guard !hasCompletedInitialLoad && !isCompletingLoad && !mediaItems.isEmpty else { return }
        
        // Get all image URLs from media items (excluding videos)
        let imageUrls = mediaItems
            .filter { !$0.type.isVideo }
            .compactMap { URL(string: $0.url) }
        
        guard !imageUrls.isEmpty else {
            // All items are videos, complete immediately
            logger.info("🎬 All items are videos - completing initial load immediately")
            hasCompletedInitialLoad = true
            return
        }
        
        // Count images in different states
        let loadedCount = imageUrls.filter { preloader.loadedImages[$0] != nil }.count
        let loadingCount = imageUrls.filter { preloader.loading.contains($0) }.count
        
        logger.debug("🔍 Load check - Total: \(imageUrls.count), Loaded: \(loadedCount), Loading: \(loadingCount)")
        
        // Only complete if:
        // 1. No images are actively loading
        // 2. We have loaded at least 50% of images OR all possible images have loaded
        let minimumLoaded = imageUrls.count / 2
        let allImagesFinal = loadingCount == 0
        let enoughLoaded = loadedCount >= minimumLoaded && loadingCount == 0
        
        if allImagesFinal {
            logger.info("🏁 All images final - Loaded: \(loadedCount)/\(imageUrls.count), triggering completion")
            isCompletingLoad = true
            
            // Add a small delay for smooth transition
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeOut(duration: 0.4)) {
                    hasCompletedInitialLoad = true
                }
            }
        } else if enoughLoaded {
            logger.info("✨ Enough images loaded - \(loadedCount)/\(imageUrls.count) (minimum: \(minimumLoaded)), triggering completion")
            isCompletingLoad = true
            
            // Add a small delay for smooth transition
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.easeOut(duration: 0.4)) {
                    hasCompletedInitialLoad = true
                }
            }
        }
    }
    
    private func performRefresh() async {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        preloader.refreshImages()
        try? await Task.sleep(for: .milliseconds(500))
    }
}


struct PresentedMedia: Identifiable, Equatable {
    let id = UUID()
    let mediaItem: MediaItem
}

// Helper to find and configure UIScrollView to remove insets
struct ScrollViewConfigurator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Delay to let SwiftUI create the ScrollView
        DispatchQueue.main.async {
            self.configureScrollView(in: view)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        configureScrollView(in: uiView)
    }
    
    private func configureScrollView(in view: UIView) {
        // Find UIScrollView by traversing the view hierarchy
        var responder: UIResponder? = view
        while responder != nil {
            if let scrollView = responder as? UIScrollView {
                // Configure to remove insets and make background transparent
                scrollView.backgroundColor = .clear
                scrollView.contentInsetAdjustmentBehavior = .never
                
                // Zero content insets to allow content to fill naturally
                scrollView.contentInset = .zero
                scrollView.scrollIndicatorInsets = .zero
                scrollView.automaticallyAdjustsScrollIndicatorInsets = false
                break
            }
            responder = responder?.next
        }
    }
}

// Apply zero content margins so scroll content extends edge-to-edge
private struct ZeroScrollContentMarginsIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        content.contentMargins(.zero, for: .scrollContent)
    }
}

#Preview {
    let preloader = ImagePreloader()
    let mediaItems = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://youtube.com/embed/dQw4w9WgXcQ",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw=="
    ].compactMap { MediaItem.from(urlString: $0) }
    
    // Preload media immediately for preview
    preloader.preloadMedia(from: mediaItems)
    
    return PhotoTabView(
        mediaItems: mediaItems,
        gridMode: .constant(PhotoTabView.GridMode.single),
        onRequestFullScreen: { _ in })
    .environmentObject(preloader)
}

#Preview("With Mock Images") {
    // Mock preloader with sample images already loaded
    class MockImagePreloader: ImagePreloader {
        override init() {
            super.init()
            // Add some mock images to simulate loaded state
            if let sampleImage = UIImage(systemName: "photo.fill") {
                let urls = [
                    "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw=="
                ].compactMap { URL(string: $0) }
                
                for url in urls {
                    self.loadedImages[url] = sampleImage
                }
            }
        }
    }
    
    let mediaItems = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw=="
    ].compactMap { MediaItem.from(urlString: $0) }
    
    return PhotoTabView(
        mediaItems: mediaItems,
        gridMode: .constant(PhotoTabView.GridMode.compact),
        onRequestFullScreen: { _ in })
    .environmentObject(MockImagePreloader())
}
