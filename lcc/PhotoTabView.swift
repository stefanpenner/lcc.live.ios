import Combine
import Foundation
import SwiftUI

struct PhotoTabView: View {
    let mediaItems: [MediaItem]
    
    @Binding public var gridMode: GridMode
    var onRequestFullScreen: (PresentedMedia) -> Void
    var onScrollActivity: (() -> Void)?
    var onScrollDirectionChanged: ((ScrollDirection) -> Void)?
    @EnvironmentObject var preloader: ImagePreloader
    @EnvironmentObject var apiService: APIService

    @Environment(\.colorScheme) var colorScheme
    @State private var isRefreshing = false
    @State private var hasCompletedInitialLoad = false
    @State private var isCompletingLoad = false // Prevent multiple completion triggers
    @State private var hasReceivedInitialPayload = false // Track if API has responded
    
    private let logger = Logger(category: .ui)
    
    enum ScrollDirection {
        case up
        case down
        case idle
    }

    // User grid mode
    public enum GridMode: String, CaseIterable, Identifiable {
        case compact = "Compact"
        case single = "Single"
        var id: String { rawValue }
    }

    private let spacing: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (spacing * 1)
            let columns = gridMode == .single ? 1 : max(1, Int(availableWidth / 180))
            let imageWidth = (availableWidth - CGFloat(columns - 1) * 5) / CGFloat(columns)
            let imageHeight = imageWidth * (gridMode == .single ? 0.9 : 0.9)
            let gridItems = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: columns)
            
            ZStack {
                // Main content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Pull-to-refresh area
                            Color.clear
                                .frame(height: 60)
                                .id("top")
                            
                            if mediaItems.isEmpty {
                                // Only show empty state after we've received API response
                                if hasReceivedInitialPayload {
                                    EmptyStateView()
                                        .frame(width: availableWidth, height: geometry.size.height * 0.6)
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
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Bottom spacer to ensure we can scroll
                        Color.clear
                            .frame(height: 100)
                            .id("bottom")
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            // Only process vertical scrolling gestures
                            let isVerticalSwipe = abs(value.translation.height) > abs(value.translation.width) * 1.5
                            
                            guard isVerticalSwipe else { return }
                            
                            let delta = value.translation.height
                            
                            // Only process if we have enough movement
                            guard abs(delta) > 20 else { return }
                            
                            #if DEBUG
                            print("📜 PhotoTabView: Vertical scroll detected, translation: \(value.translation)")
                            #endif
                            
                            if delta < -30 {
                                // Scrolling down (content moving up) - hide controls
                                #if DEBUG
                                print("📜 PhotoTabView: Scroll DOWN - hiding controls")
                                #endif
                                onScrollDirectionChanged?(.down)
                            } else if delta > 30 {
                                // Scrolling up (content moving down) - show controls
                                #if DEBUG
                                print("📜 PhotoTabView: Scroll UP - showing controls")
                                #endif
                                onScrollDirectionChanged?(.up)
                            }
                        }
                )
                }
                .refreshable {
                    await performRefresh()
                }
                .ignoresSafeArea(edges: .bottom)
                .safeAreaInset(edge: .bottom) {
                    // Reserve space for the floating GridModeToggle
                    Color.clear
                        .frame(height: 70)
                }
                
                // Unified loading overlay during initial load
                if !hasCompletedInitialLoad && !mediaItems.isEmpty {
                    VStack(spacing: 0) {
                        // Spacer below menu
                        Color.clear
                            .frame(height: 80)
                        
                        InitialLoadingView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                    .transition(.opacity)
                }
            }
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
            // Mark that we've received API payload once we have items
            if !isEmpty {
                hasReceivedInitialPayload = true
            }
        }
        .onChange(of: apiService.isLoading) { _, isLoading in
            // Mark payload received when API completes (whether we have items or not)
            if !isLoading {
                hasReceivedInitialPayload = true
                
                // If API loading completes with no images, mark initial load as done
                if mediaItems.isEmpty {
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
            hasCompletedInitialLoad = true
            return
        }
        
        // Count images in different states
        let loadedCount = imageUrls.filter { preloader.loadedImages[$0] != nil }.count
        let loadingCount = imageUrls.filter { preloader.loading.contains($0) }.count
        
        // Only complete if:
        // 1. No images are actively loading
        // 2. We have loaded at least 50% of images OR all possible images have loaded
        let minimumLoaded = imageUrls.count / 2
        let allImagesFinal = loadingCount == 0
        let enoughLoaded = loadedCount >= minimumLoaded && loadingCount == 0
        
        if allImagesFinal || enoughLoaded {
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

private struct MediaCell: View {
    let mediaItem: MediaItem
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let colorScheme: ColorScheme
    let hasCompletedInitialLoad: Bool
    let onTap: () -> Void
    let onRetry: () -> Void

    @EnvironmentObject var preloader: ImagePreloader
    @State private var isRetrying = false

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if mediaItem.type.isVideo {
                    // Show YouTube thumbnail with play button
                    if case .youtubeVideo(let embedURL) = mediaItem.type {
                        YouTubeThumbnailView(
                            embedURL: embedURL,
                            width: imageWidth,
                            height: imageHeight
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .onTapGesture {
                            onTap()
                        }
                        .accessibilityLabel("YouTube video")
                        .accessibilityAddTraits(.isButton)
                    }
                } else {
                    // Show image (existing code)
                    let url = URL(string: mediaItem.url)!
                    let loadedImage = preloader.loadedImages[url]
                    
                    if let uiImage = loadedImage {
                        // Show preloaded image
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .onTapGesture {
                                onTap()
                            }
                            .accessibilityLabel("Camera image")
                            .accessibilityAddTraits(.isImage)
                    } else if preloader.loading.contains(url) || isRetrying || !hasCompletedInitialLoad {
                        // Show shimmer loading state (including during initial load)
                        ShimmerView(width: imageWidth, height: imageHeight, colorScheme: colorScheme)
                    } else {
                        // Show error state with retry (only after initial load completes)
                        Button(action: {
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                            isRetrying = true
                            onRetry()
                            // Reset after brief delay to allow loading state to show
                            Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                isRetrying = false
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(Color.accentColor.opacity(0.8))
                                Text("Tap to retry")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: imageWidth, height: imageHeight)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: colorScheme == .dark ?
                                                [Color(red: 0.18, green: 0.13, blue: 0.13), Color(red: 0.22, green: 0.16, blue: 0.18)] :
                                                [Color(red: 0.99, green: 0.95, blue: 0.92), Color(red: 0.95, green: 0.92, blue: 0.99)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Failed to load image")
                        .accessibilityHint("Tap to retry loading")
                    }
                    
                    // Subtle border while updating (only for images)
                    let isLoading = preloader.loading.contains(url)
                    let fadeDate = preloader.fadingOut[url]
                    let isFadingOut = fadeDate != nil
                    let fadeProgress: CGFloat = {
                        guard let fadeDate = fadeDate else { return 0 }
                        let elapsed = CGFloat(Date().timeIntervalSince(fadeDate))
                        let duration: CGFloat = 3.0
                        return min(1, max(0, elapsed / duration))
                    }()
                    let borderOpacity: CGFloat = isFadingOut ? (1 - fadeProgress) : (isLoading ? 0.3 : 0)
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor.opacity(0.60), lineWidth: 4)
                        .frame(width: imageWidth, height: imageHeight)
                        .opacity(borderOpacity)
                        .animation(.easeInOut(duration: 0.4), value: borderOpacity)
                }
            }
        }
    }
}

struct PresentedMedia: Identifiable, Equatable {
    let id = UUID()
    let mediaItem: MediaItem
}

// MARK: - Helper Views

private struct LastUpdatedView: View {
    let lastRefreshed: Date
    @State private var currentTime = Date()
    
    private var timeAgo: String {
        let seconds = Int(currentTime.timeIntervalSince(lastRefreshed))
        if seconds < 5 {
            return "Just now"
        } else if seconds < 60 {
            return "\(seconds)s ago"
        } else if seconds < 3600 {
            return "\(seconds / 60)m ago"
        } else {
            return "\(seconds / 3600)h ago"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 11, weight: .medium))
            Text(timeAgo)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.secondary.opacity(0.7))
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemBackground).opacity(0.7))
        )
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
        .accessibilityLabel("Last updated \(timeAgo)")
    }
}

private struct InitialLoadingView: View {
    @State private var isAnimating = false
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer pulsing ring - Liquid Glass
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.3),
                                Color.accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.0 : 1.0)
                
                // Middle ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.5),
                                Color.accentColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)
                    .opacity(isAnimating ? 0.2 : 1.0)
                
                // Inner core - Solid glass
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentColor.opacity(0.6),
                                    Color.accentColor.opacity(0.3),
                                    Color.accentColor.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    // Spinning shimmer
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            Color.accentColor.opacity(0.8),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(phase * 360))
                }
                .shadow(color: Color.accentColor.opacity(0.4), radius: 10)
            }
            
            VStack(spacing: 8) {
                Text("Loading Streams")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Preparing your live feed...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            // Pulsing animation
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            
            // Spinning animation
            withAnimation(
                .linear(duration: 2.0)
                .repeatForever(autoreverses: false)
            ) {
                phase = 1.0
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Streams Available")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("Pull down to refresh")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No streams available. Pull down to refresh.")
    }
}

private struct ShimmerView: View {
    let width: CGFloat
    let height: CGFloat
    let colorScheme: ColorScheme
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: colorScheme == .dark ? [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.15, green: 0.15, blue: 0.2),
                        Color(red: 0.1, green: 0.1, blue: 0.15)
                    ] : [
                        Color(red: 0.96, green: 0.89, blue: 0.90),
                        Color(red: 0.90, green: 0.93, blue: 0.98),
                        Color(red: 0.96, green: 0.89, blue: 0.90)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.3),
                                .init(color: .black, location: 0.7),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase * width * 2 - width)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
            .accessibilityLabel("Loading image")
    }
}

// Preference key for scroll offset tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
        onRequestFullScreen: { _ in },
        onScrollActivity: nil,
        onScrollDirectionChanged: nil)
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
        onRequestFullScreen: { _ in },
        onScrollActivity: nil,
        onScrollDirectionChanged: nil)
    .environmentObject(MockImagePreloader())
}
