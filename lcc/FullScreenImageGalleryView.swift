import SwiftUI

struct FullScreenImageGalleryView: View {
    let images: [String]
    let initialURL: URL
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
    @State private var isTransitioning = false
    @State private var retryingURLs: Set<URL> = []
    
    init(images: [String], initialURL: URL, onDismiss: @escaping () -> Void) {
        self.images = images
        self.initialURL = initialURL
        self.onDismiss = onDismiss
        
        // Find the initial index
        if let index = images.firstIndex(where: { URL(string: $0) == initialURL }) {
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
                    .onTapGesture {
                        print("DEBUG: Tap on background")
                        toggleControls()
                    }
                
                // Current image only - prevents adjacent images from showing
                ZStack {
                    if let imageUrlString = images[safe: currentIndex],
                       let url = URL(string: imageUrlString) {
                        if let image = preloader.loadedImages[url] {
                            ZoomableDismissableImageView(
                                image: image,
                                geometry: geometry,
                                onFlickDismiss: onDismiss
                            )
                            .id(currentIndex) // Force recreation on index change
                        } else if preloader.loading.contains(url) || retryingURLs.contains(url) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                        } else {
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
                                    // Remove from retrying set after a delay to allow preloader.loading to take over
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
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle()) // Make entire area tappable for gestures
                .offset(x: offset, y: verticalOffset)
                .scaleEffect(1.0 - dismissProgress * 0.15) // Subtle scale down as dismissing
                .clipShape(RoundedRectangle(cornerRadius: dismissProgress * 16)) // Round corners as dismissing
                .simultaneousGesture(
                    DragGesture(minimumDistance: 15)
                        .onChanged { value in
                            let translation = value.translation
                            let horizontalMovement = abs(translation.width)
                            let verticalMovement = abs(translation.height)
                            
                            // Determine if this is a horizontal or vertical gesture
                            if verticalMovement > horizontalMovement && verticalMovement > 20 {
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
                                }
                            } else if horizontalMovement > 20 {
                                // Horizontal gesture for navigation
                                isDragging = true
                                isDismissing = false
                                
                                // Lock vertical position during horizontal drag
                                verticalOffset = 0
                                dismissProgress = 0
                                
                                // Add edge resistance (rubberband effect)
                                if (currentIndex == 0 && translation.width > 0) || (currentIndex == images.count - 1 && translation.width < 0) {
                                    offset = translation.width * 0.3
                                } else {
                                    offset = translation.width
                                }
                            }
                        }
                        .onEnded { value in
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
                                
                                let velocity = value.predictedEndTranslation.width - value.translation.width
                                let threshold: CGFloat = geometry.size.width * 0.15
                                let velocityThreshold: CGFloat = 500
                                
                                let shouldGoBack = (translation.width > threshold || velocity > velocityThreshold) && currentIndex > 0
                                let shouldGoForward = (translation.width < -threshold || velocity < -velocityThreshold) && currentIndex < images.count - 1
                                
                                if shouldGoBack {
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    #endif
                                    
                                    // Complete the slide animation
                                    isTransitioning = true
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        offset = geometry.size.width
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        currentIndex -= 1
                                        offset = 0
                                        isTransitioning = false
                                    }
                                    resetControlsTimer()
                                } else if shouldGoForward {
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    #endif
                                    
                                    // Complete the slide animation
                                    isTransitioning = true
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        offset = -geometry.size.width
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        currentIndex += 1
                                        offset = 0
                                        isTransitioning = false
                                    }
                                    resetControlsTimer()
                                } else {
                                    // Snap back smoothly with your finger's momentum
                                    let velocity = CGFloat(velocity) / geometry.size.width
                                    withAnimation(.interpolatingSpring(mass: 1, stiffness: 300, damping: 30, initialVelocity: velocity)) {
                                        offset = 0
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
                if images.count > 1 {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<images.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.5))
                                    .frame(width: 7, height: 7)
                                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: currentIndex)
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
                    .allowsHitTesting(false)
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
                    Text("\(currentIndex + 1) of \(images.count)")
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
        .accessibilityLabel("Image \(currentIndex + 1) of \(images.count)")
        .accessibilityHint("Swipe left or right to navigate between images. Tap to toggle controls.")
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

