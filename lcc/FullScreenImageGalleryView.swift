import SwiftUI

struct FullScreenImageGalleryView: View {
    let mediaItems: [MediaItem]
    let initialMediaItem: MediaItem
    let onDismiss: () -> Void
    
    @EnvironmentObject var preloader: ImagePreloader
    @State private var currentIndex: Int = 0
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @GestureState private var dragState: CGFloat = 0
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    
    // Interactive dismissal state
    @State private var dismissProgress: CGFloat = 0
    @State private var verticalOffset: CGFloat = 0
    @State private var isDismissing = false
    @State private var retryingURLs: Set<URL> = []
    
    // Zoom state tracking
    @State private var isImageZoomed = false
    
    // Gesture direction locking
    @State private var gestureDirection: GestureDirection? = nil
    
    enum GestureDirection {
        case horizontal
        case vertical
    }
    
    // Spacing between images - set to 0 for seamless canvas feel
    private let imageSpacing: CGFloat = 0
    
    init(mediaItems: [MediaItem], initialMediaItem: MediaItem, onDismiss: @escaping () -> Void) {
        self.mediaItems = mediaItems
        self.initialMediaItem = initialMediaItem
        self.onDismiss = onDismiss
        
        // Find the initial index
        if let index = mediaItems.firstIndex(where: { $0.id == initialMediaItem.id }) {
            _currentIndex = State(initialValue: index)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background that fades as you dismiss
                Color.black
                    .opacity(1.0 - dismissProgress * 0.7)
                    .edgesIgnoringSafeArea(.all)
                
                // Carousel with current, previous, and next media items for seamless swiping
                ZStack {
                    ForEach(max(0, currentIndex - 1)...min(mediaItems.count - 1, currentIndex + 1), id: \.self) { index in
                        if let mediaItem = mediaItems[safe: index] {
                            ZStack {
                                if mediaItem.type.isVideo {
                                    // Show YouTube player for videos
                                    if case .youtubeVideo(let embedURL) = mediaItem.type {
                                        YouTubePlayerView(embedURL: embedURL, autoplay: index == currentIndex)
                                            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                            .background(Color.black)
                                    }
                                } else if let url = URL(string: mediaItem.url) {
                                    // Show image viewer for images
                                    if let image = preloader.loadedImages[url] {
                                        ZoomableDismissableImageView(
                                            image: image,
                                            geometry: geometry,
                                            onFlickDismiss: onDismiss,
                                            onZoomChanged: { isZoomed in
                                                isImageZoomed = isZoomed
                                            }
                                        )
                                    } else if preloader.loading.contains(url) || retryingURLs.contains(url) {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(1.5)
                                    } else if index == currentIndex {
                                        // Only show retry button for current image
                                        VStack(spacing: 16) {
                                            Image(systemName: "exclamationmark.triangle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white.opacity(0.7))
                                            Text("Image failed to load")
                                                .foregroundColor(.white.opacity(0.7))
                                            Button(action: {
                                                #if os(iOS)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                #endif
                                                retryingURLs.insert(url)
                                                preloader.retryImage(for: url)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    retryingURLs.remove(url)
                                                }
                                            }) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "arrow.clockwise")
                                                    Text("Retry")
                                                }
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.accentColor.opacity(0.2))
                                                )
                                                .foregroundColor(.accentColor)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .allowsHitTesting(true)
                                    } else {
                                        // Placeholder for failed images
                                        Color.black.opacity(0.3)
                                    }
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(x: CGFloat(index - currentIndex) * (geometry.size.width + imageSpacing) + offset)
                            .id("media-\(index)")
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle()) // Make entire area tappable for gestures
                .offset(y: verticalOffset)
                .scaleEffect(1.0 - dismissProgress * 0.15) // Subtle scale down as dismissing
                .clipShape(RoundedRectangle(cornerRadius: dismissProgress * 16)) // Round corners as dismissing
                .onTapGesture {
                    toggleControls()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            // Don't allow page swiping when image is zoomed
                            guard !isImageZoomed else { return }
                            
                            let translation = value.translation
                            let horizontalMovement = abs(translation.width)
                            let verticalMovement = abs(translation.height)
                            
                            // Lock in gesture direction on first significant movement
                            if gestureDirection == nil {
                                // Determine direction as soon as there's any meaningful movement
                                if horizontalMovement > 5 || verticalMovement > 5 {
                                    if verticalMovement > horizontalMovement {
                                        gestureDirection = .vertical
                                    } else {
                                        gestureDirection = .horizontal
                                    }
                                }
                            }
                            
                            // Handle gesture based on locked direction
                            if gestureDirection == .vertical {
                                // Vertical gesture for dismissal
                                isDismissing = true
                                isDragging = false
                                
                                // Lock horizontal position during vertical drag
                                offset = 0
                                
                                // Only allow downward drag
                                if translation.height > 0 {
                                    verticalOffset = translation.height
                                    // Calculate progress (0 to 1)
                                    dismissProgress = min(1.0, translation.height / (geometry.size.height * 0.5))
                                } else {
                                    verticalOffset = 0
                                    dismissProgress = 0
                                }
                            } else if gestureDirection == .horizontal {
                                // Horizontal gesture for navigation
                                isDragging = true
                                isDismissing = false
                                
                                // ALWAYS lock vertical position during horizontal drag
                                verticalOffset = 0
                                dismissProgress = 0
                                
                                // Add edge resistance (rubberband effect)
                                if (currentIndex == 0 && translation.width > 0) || (currentIndex == mediaItems.count - 1 && translation.width < 0) {
                                    offset = translation.width * 0.3
                                } else {
                                    offset = translation.width
                                }
                            } else {
                                // No direction locked yet - keep everything at zero
                                verticalOffset = 0
                                dismissProgress = 0
                                offset = 0
                            }
                        }
                        .onEnded { value in
                            // Reset gesture direction lock for next gesture
                            defer { gestureDirection = nil }
                            
                            // Don't allow page swiping when image is zoomed
                            guard !isImageZoomed else { return }
                            
                            let translation = value.translation
                            let horizontalMovement = abs(translation.width)
                            let verticalMovement = abs(translation.height)
                            
                            // Check if this was a dismiss gesture
                            if isDismissing && verticalMovement > horizontalMovement {
                                let velocity = value.predictedEndTranslation.height - value.location.y
                                let dismissThreshold: CGFloat = geometry.size.height * 0.25
                                let velocityThreshold: CGFloat = 500
                                
                                // Ensure horizontal offset stays locked
                                offset = 0
                                
                                if translation.height > dismissThreshold || velocity > velocityThreshold {
                                    // Complete dismissal with animation
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        verticalOffset = geometry.size.height
                                        dismissProgress = 1.0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        onDismiss()
                                    }
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                                        verticalOffset = 0
                                        dismissProgress = 0
                                    }
                                }
                                isDismissing = false
                            } else if isDragging {
                                // Handle horizontal navigation
                                isDragging = false
                                
                                // Ensure vertical offset is locked at zero
                                verticalOffset = 0
                                dismissProgress = 0
                                
                                let velocity = value.predictedEndTranslation.width - value.translation.width
                                let threshold: CGFloat = geometry.size.width * 0.2  // Slightly higher for more intentional swipes
                                let velocityThreshold: CGFloat = 300  // Lower threshold for quicker response to fast swipes
                                
                                let shouldGoBack = (translation.width > threshold || velocity > velocityThreshold) && currentIndex > 0
                                let shouldGoForward = (translation.width < -threshold || velocity < -velocityThreshold) && currentIndex < mediaItems.count - 1
                                
                                if shouldGoBack {
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                    
                                    // Animate slide to completion FIRST, then update index
                                    // This creates a seamless canvas effect
                                    let screenWidth = geometry.size.width
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                        offset = screenWidth  // Complete the slide to the right
                                    }
                                    
                                    // After animation completes, update index and reset offset
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        currentIndex -= 1
                                        offset = 0
                                    }
                                    resetControlsTimer()
                                } else if shouldGoForward {
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                    
                                    // Animate slide to completion FIRST, then update index
                                    let screenWidth = geometry.size.width
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                        offset = -screenWidth  // Complete the slide to the left
                                    }
                                    
                                    // After animation completes, update index and reset offset
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        currentIndex += 1
                                        offset = 0
                                    }
                                    resetControlsTimer()
                                } else {
                                    // Snap back smoothly with slightly bouncier spring physics
                                    withAnimation(.interpolatingSpring(stiffness: 280, damping: 28)) {
                                        offset = 0
                                        verticalOffset = 0
                                        dismissProgress = 0
                                    }
                                }
                            } else {
                                // Reset everything
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    verticalOffset = 0
                                    dismissProgress = 0
                                    offset = 0
                                }
                            }
                        }
                )
                
                // Page indicator (with blur)
                if mediaItems.count > 1 {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<mediaItems.count, id: \.self) { index in
                                Button(action: {
                                    // Don't navigate if already on this image or if zoomed
                                    guard index != currentIndex && !isImageZoomed else { return }
                                    
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                    
                                    // Calculate direction and distance
                                    let direction = index > currentIndex ? -1 : 1
                                    let distance = abs(index - currentIndex)
                                    
                                    // Animate slide in the appropriate direction
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                        offset = CGFloat(direction) * geometry.size.width * CGFloat(distance)
                                    }
                                    
                                    // After animation completes, update index and reset offset
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        currentIndex = index
                                        offset = 0
                                    }
                                    
                                    resetControlsTimer()
                                }) {
                                    Circle()
                                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 7, height: 7)
                                        .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: currentIndex)
                                        .contentShape(Circle().scale(2.5)) // Larger tap target
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                                .background(.ultraThinMaterial, in: Capsule())
                        )
                        .padding(.bottom, 50)
                    }
                    .opacity(showControls && !isDismissing ? 1 : 0)
                    .scaleEffect(showControls && !isDismissing ? 1 : 0.9)
                    .animation(.easeInOut(duration: 0.25), value: showControls)
                    .zIndex(10)
                }
                
                // Close button (with blur)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .background(.ultraThinMaterial, in: Circle())
                                )
                        }
                        .padding()
                        .accessibilityLabel("Close")
                        .accessibilityHint("Dismiss full screen view")
                    }
                    Spacer()
                }
                .opacity((showControls && !isDismissing) ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: showControls)
                .zIndex(10)
                
                // Counter (with blur)
                VStack {
                    Text("\(currentIndex + 1) of \(mediaItems.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                                .background(.ultraThinMaterial, in: Capsule())
                        )
                        .padding(.top, 12)
                    Spacer()
                }
                .opacity((showControls && !isDismissing) ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: showControls)
                .zIndex(10)
            }
        }
        .statusBar(hidden: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Media \(currentIndex + 1) of \(mediaItems.count)")
        .accessibilityHint("Swipe left or right to navigate between items. Tap to toggle controls.")
        .onAppear {
            resetControlsTimer()
        }
        .onDisappear {
            controlsTimer?.invalidate()
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleControls() {
        print("DEBUG: toggleControls called, current: \(showControls)")
        withAnimation(.easeInOut(duration: 0.25)) {
            showControls.toggle()
        }
        print("DEBUG: after toggle: \(showControls)")
        if showControls {
            resetControlsTimer()
        } else {
            controlsTimer?.invalidate()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        
        // Show controls
        withAnimation(.easeInOut(duration: 0.25)) {
            showControls = true
        }
        
        // Auto-hide after 3 seconds
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                showControls = false
            }
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

