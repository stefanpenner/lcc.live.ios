import Combine
import Foundation
import SwiftUI

struct PhotoTabView: View {
    let images: [String]
    
    @Binding public var gridMode: GridMode
    var onRequestFullScreen: (PresentedImage) -> Void
    var onScrollActivity: (() -> Void)?
    var onScrollDirectionChanged: ((ScrollDirection) -> Void)?
    @EnvironmentObject var preloader: ImagePreloader

    @Environment(\.colorScheme) var colorScheme
    @State private var isRefreshing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    
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
            
            ScrollView {
                VStack(spacing: 0) {
                    // Pull-to-refresh area
                    Color.clear
                        .frame(height: 60)
                    
                    if images.isEmpty {
                        EmptyStateView()
                            .frame(width: availableWidth, height: geometry.size.height * 0.6)
                    } else {
                        LazyVGrid(columns: gridItems, spacing: spacing) {
                            ForEach(images, id: \.self) { imageUrl in
                                PhotoCell(
                                    imageUrl: imageUrl,
                                    imageWidth: imageWidth,
                                    imageHeight: imageHeight,
                                    colorScheme: colorScheme,
                                    onTap: {
                                        if let url = URL(string: imageUrl), preloader.loadedImages[url] != nil {
                                            onRequestFullScreen(PresentedImage(url: url))
                                        }
                                    },
                                    onRetry: {
                                        if let url = URL(string: imageUrl) {
                                            preloader.retryImage(for: url)
                                        }
                                    }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            GeometryReader { scrollGeo in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeo.frame(in: .named("scroll")).minY)
                            }
                        )
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                let delta = value - lastScrollOffset
                
                // Detect scroll direction with threshold to avoid jitter
                if abs(delta) > 10 {
                    if delta < -50 {
                        // Scrolling down (content moving up)
                        onScrollDirectionChanged?(.down)
                    } else if delta > 50 {
                        // Scrolling up (content moving down)
                        onScrollDirectionChanged?(.up)
                    }
                    
                    onScrollActivity?()
                    lastScrollOffset = value
                }
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
        }
        .onAppear {
            preloader.preloadImages(from: images)
            preloader.refreshImages()
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

private struct PhotoCell: View {
    let imageUrl: String
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let colorScheme: ColorScheme
    let onTap: () -> Void
    let onRetry: () -> Void

    @EnvironmentObject var preloader: ImagePreloader
    @State private var isRetrying = false

    var body: some View {
        let url = URL(string: imageUrl)!
        let loadedImage = preloader.loadedImages[url]
        
        ZStack(alignment: .top) {
            Group {
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
                } else if preloader.loading.contains(url) || isRetrying {
                    // Show shimmer loading state
                    ShimmerView(width: imageWidth, height: imageHeight, colorScheme: colorScheme)
                } else {
                    // Show error state with retry
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
            }

            // Subtle border while updating
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

struct PresentedImage: Identifiable, Equatable {
    let id = UUID()
    let url: URL
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

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Images Available")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("Pull down to refresh")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No images available. Pull down to refresh.")
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
    let images = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw=="
    ]
    
    // Preload images immediately for preview
    preloader.preloadImages(from: images)
    
    return PhotoTabView(
        images: images,
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
    
    let images = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw=="
    ]
    
    return PhotoTabView(
        images: images,
        gridMode: .constant(PhotoTabView.GridMode.compact),
        onRequestFullScreen: { _ in },
        onScrollActivity: nil,
        onScrollDirectionChanged: nil)
    .environmentObject(MockImagePreloader())
}
