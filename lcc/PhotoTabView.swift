import SwiftUI
import Combine

struct PhotoTabView: View {
    let images: [String]
    let title: String
    let icon: String
    var refreshImagesTrigger: Int = 0 // default for backward compatibility
    @Binding var selectedTab: Int
    let tabIndex: Int
    let tabCount: Int

    @StateObject private var preloader = ImagePreloader()
    @Environment(\.colorScheme) var colorScheme

    // Layout constants
    private let minImageWidth: CGFloat = 340
    private let spacing: CGFloat = 20

    // Use optional PresentedImage for full screen state
    @State private var fullScreenImage: PresentedImage? = nil
    @State private var overlayUUID = UUID()
    @State private var isRefreshing = false

    // User grid mode
    private enum GridMode: String, CaseIterable, Identifiable {
        case compact = "Compact"
        case single = "Single"
        var id: String { rawValue }
    }
    @State private var gridMode: GridMode = .compact

    // Add enum for image size
    private enum ImageSizeCategory {
        case small, medium, large
        var minWidth: CGFloat {
            switch self {
            case .small: return 100
            case .medium: return 180
            case .large: return 260
            }
        }
        var maxWidth: CGFloat {
            switch self {
            case .small: return 160
            case .medium: return 260
            case .large: return 400
            }
        }
        var aspectRatio: CGFloat {
            switch self {
            case .small: return 1.0
            case .medium: return 0.8
            case .large: return 0.7
            }
        }
    }

    @State private var isToggleVisible: Bool = true
    @State private var lastScrollDate: Date = Date()
    @State private var showFloatingButton: Bool = false
    private let toggleFadeDuration: Double = 0.25
    private let toggleHideDelay: Double = 1.0
    private let floatingButtonSize: CGFloat = 36
    private let floatingButtonPadding: CGFloat = 12
    private var gridIcon: String { "square.grid.2x2" }
    private var toggleAnimation: Animation { .easeInOut(duration: toggleFadeDuration) }

    // Scroll offset preference key
    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width - (spacing * 2)
                let (columns, imageWidth, imageHeight, gridItems): (Int, CGFloat, CGFloat, [GridItem]) = {
                    let isLandscape = geometry.size.width > geometry.size.height
                    switch gridMode {
                    case .compact:
                        let compactColumns = max(2, min(4, Int(availableWidth / 220)))
                        let imageWidth = (availableWidth - (CGFloat(compactColumns - 1) * spacing)) / CGFloat(compactColumns)
                        let imageHeight = imageWidth * 0.7
                        let gridItems = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: compactColumns)
                        return (compactColumns, imageWidth, imageHeight, gridItems)
                    case .single:
                        let maxSingleWidth: CGFloat = 430
                        if isLandscape {
                            let columns = 2
                            let totalSpacing = spacing
                            let imageWidth = min((availableWidth - totalSpacing) / 2, maxSingleWidth)
                            let imageHeight = imageWidth * 0.7
                            let gridItems = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: columns)
                            return (columns, imageWidth, imageHeight, gridItems)
                        } else {
                            let columns = 1
                            let imageWidth = min(availableWidth, maxSingleWidth)
                            let imageHeight = imageWidth * 0.7
                            let gridItems = [GridItem(.fixed(imageWidth), spacing: spacing)]
                            return (columns, imageWidth, imageHeight, gridItems)
                        }
                    }
                }()
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVGrid(columns: gridItems, spacing: spacing) {
                                ForEach(images, id: \.self) { imageUrl in
                                    PhotoCell(
                                        imageUrl: imageUrl,
                                        preloadedImage: preloader.loadedImages[URL(string: imageUrl) ?? URL(fileURLWithPath: "")],
                                        imageWidth: imageWidth,
                                        imageHeight: imageHeight,
                                        colorScheme: colorScheme,
                                        onTap: { _ in
                                            if let url = URL(string: imageUrl) {
                                                overlayUUID = UUID()
                                                fullScreenImage = PresentedImage(url: url)
                                            }
                                        }
                                    )
                                    .environmentObject(preloader)
                                }
                            }
                            .frame(maxWidth: gridMode == .single ? (columns == 1 ? 430 : (imageWidth * 2 + spacing)) : .infinity)
                            .frame(maxWidth: .infinity)
                            // Show only when pulling to refresh
                            if isRefreshing {
                                Text("Last refreshed: \(preloader.lastRefreshed, formatter: dateFormatter)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                        }
                        .background(
                            GeometryReader { scrollGeo in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeo.frame(in: .named("scrollView")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        let now = Date()
                        lastScrollDate = now
                        if isToggleVisible {
                            withAnimation(toggleAnimation) {
                                isToggleVisible = false
                            }
                        }
                        // Schedule to show toggle after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + toggleHideDelay) {
                            if Date().timeIntervalSince(lastScrollDate) >= toggleHideDelay {
                                withAnimation(toggleAnimation) {
                                    isToggleVisible = true
                                    showFloatingButton = false
                                }
                            } else {
                                // If user is still scrolling, show floating button
                                withAnimation(toggleAnimation) {
                                    isToggleVisible = false
                                    showFloatingButton = true
                                }
                            }
                        }
                        // Always show floating button if toggle is hidden
                        if !isToggleVisible {
                            withAnimation(toggleAnimation) {
                                showFloatingButton = true
                            }
                        }
                    }
                }
            }
            // Overlay the fullscreen image if needed
            if let presented = fullScreenImage {
                FullScreenImageView(url: presented.url, preloader: preloader) {
                    withAnimation { fullScreenImage = nil }
                }
                .id(overlayUUID)
                .transition(.opacity)
                .zIndex(1)
            }
            // Floating grid mode toggle/floating button always overlays content
            if fullScreenImage == nil {
                VStack {
                    HStack {
                        Spacer()
                        if isToggleVisible {
                            HStack(spacing: 8) {
                                Button(action: { gridMode = .compact }) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(gridMode == .compact ? .accentColor : .secondary)
                                        .padding(6)
                                        .background(
                                            Circle()
                                                .fill(gridMode == .compact ? Color.accentColor.opacity(0.15) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                                Button(action: { gridMode = .single }) {
                                    Image(systemName: "rectangle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(gridMode == .single ? .accentColor : .secondary)
                                        .padding(6)
                                        .background(
                                            Circle()
                                                .fill(gridMode == .single ? Color.accentColor.opacity(0.15) : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground).opacity(0.7))
                                    .shadow(radius: 2)
                            )
                            .padding([.top, .trailing], 8)
                            .animation(toggleAnimation, value: isToggleVisible)
                        } else if showFloatingButton {
                            Button(action: {
                                withAnimation(toggleAnimation) {
                                    isToggleVisible = true
                                    showFloatingButton = false
                                }
                            }) {
                                Image(systemName: gridIcon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.accentColor)
                                    .frame(width: floatingButtonSize, height: floatingButtonSize)
                                    .background(
                                        Circle()
                                            .fill(Color(.systemBackground).opacity(0.85))
                                            .shadow(radius: 2)
                                    )
                            }
                            .padding([.top, .trailing], floatingButtonPadding)
                            .transition(.opacity)
                            .animation(toggleAnimation, value: showFloatingButton)
                        }
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
                .zIndex(2)
            }
        }
        .animation(.easeInOut, value: fullScreenImage)
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    // Only trigger if horizontal is much greater than vertical
                    if abs(horizontalAmount) > abs(verticalAmount) * 1.5 {
                        if horizontalAmount < -50, tabIndex < tabCount - 1 {
                            selectedTab = tabIndex + 1
                        } else if horizontalAmount > 50, tabIndex > 0 {
                            selectedTab = tabIndex - 1
                        }
                    }
                }
        )
        .onAppear {
            preloader.preloadImages(from: images)
            preloader.refreshImages()
        }
        .onChange(of: refreshImagesTrigger) { _ in
            preloader.refreshImages()
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
}

private struct PhotoCell: View {
    let imageUrl: String
    let preloadedImage: UIImage?
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let colorScheme: ColorScheme
    let onTap: (UIImage) -> Void
    @EnvironmentObject var preloader: ImagePreloader
    
    var body: some View {
        let url = URL(string: imageUrl) ?? URL(fileURLWithPath: "")
        let isLoading = preloader.loading.contains(url)
        let fadeDate = preloader.fadingOut[url]
        let isFadingOut = fadeDate != nil
        let fadeProgress: CGFloat = {
            guard let fadeDate = fadeDate else { return 0 }
            let elapsed = CGFloat(Date().timeIntervalSince(fadeDate))
            let duration: CGFloat = 3.0
            return min(1, max(0, elapsed / duration))
        }()
        ZStack(alignment: .top) {
            Group {
                if let image = preloadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(image) }
                } else {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: imageWidth, height: imageHeight)
                                .background(
                                    LinearGradient(
                                        colors: colorScheme == .dark ?
                                            [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.15, green: 0.15, blue: 0.2)] :
                                            [Color(red: 0.96, green: 0.89, blue: 0.90), Color(red: 0.85, green: 0.89, blue: 0.96)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageWidth, height: imageHeight)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageWidth, height: imageHeight)
                                .background(
                                    LinearGradient(
                                        colors: colorScheme == .dark ?
                                            [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.15, green: 0.15, blue: 0.2)] :
                                            [Color(red: 0.96, green: 0.89, blue: 0.90), Color(red: 0.85, green: 0.89, blue: 0.96)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: imageWidth, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            // Subtle border while updating
            let borderOpacity: CGFloat = isFadingOut ? (1 - fadeProgress) : (isLoading ? 0.3 : 0)
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accentColor.opacity(0.60), lineWidth: 4)
                .frame(width: imageWidth, height: imageHeight)
                .opacity(borderOpacity)
                .animation(.easeInOut(duration: 0.4), value: borderOpacity)
        }
    }
}

// For .fullScreenCover(item:) to work with URL
struct PresentedImage: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

// DateFormatter for last refreshed
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()
