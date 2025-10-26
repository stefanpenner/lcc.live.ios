import SwiftUI

struct MainView: View {
    let mediaItems: (lcc: [MediaItem], bcc: [MediaItem])
    @EnvironmentObject var preloader: ImagePreloader

    @State private var selectedTab = 0
    @State private var refreshImagesTrigger = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isAnyFullScreen: Bool = false
    @State private var gridMode: PhotoTabView.GridMode = .single
    let tabBarHeight: CGFloat = 36
    
    // Horizontal scroll state
    @State private var scrollOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    @State private var fullScreenMedia: PresentedMedia? = nil
    @State private var overlayUUID = UUID()
    @State private var showUIControls = true
    @State private var uiControlsTimer: Timer?
    @State private var showConnectionDetails = false
    
    private var currentMediaItems: [MediaItem] {
        selectedTab == 0 ? mediaItems.lcc : mediaItems.bcc
    }
    
    var lccPhotoTab: some View {
        PhotoTabView(
            mediaItems: mediaItems.lcc,
            gridMode: $gridMode,
            onRequestFullScreen: { media in
                overlayUUID = UUID()
                fullScreenMedia = media
            },
            onScrollActivity: resetUIControlsTimer,
            onScrollDirectionChanged: handleScrollDirection
        )
        .tag(0)
    }
    
    var bccPhotoTab: some View {
        PhotoTabView(
            mediaItems: mediaItems.bcc,
            gridMode: $gridMode,
            onRequestFullScreen: { media in
                overlayUUID = UUID()
                fullScreenMedia = media
            },
            onScrollActivity: resetUIControlsTimer,
            onScrollDirectionChanged: handleScrollDirection
        )
        .tag(1)
    }
    
    private func resetUIControlsTimer() {
        // Cancel any existing timer
        uiControlsTimer?.invalidate()
        
        // Show controls
        withAnimation(.easeOut(duration: 0.3)) {
            showUIControls = true
        }
        
        // Auto-hide after 3 seconds of no activity (unless connection dialog is open)
        uiControlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            // Don't hide if connection details dialog is open
            if !showConnectionDetails {
                withAnimation(.easeOut(duration: 0.3)) {
                    showUIControls = false
                }
            }
        }
    }
    
    private func handleScrollDirection(_ direction: PhotoTabView.ScrollDirection) {
        #if DEBUG
        print("📱 MainView: handleScrollDirection called with: \(direction)")
        #endif
        
        switch direction {
        case .down:
            // Scrolling down - hide controls immediately
            #if DEBUG
            print("📱 MainView: Hiding controls")
            #endif
            uiControlsTimer?.invalidate()
            withAnimation(.easeOut(duration: 0.3)) {
                showUIControls = false
            }
        case .up:
            // Scrolling up - show controls and start auto-hide timer
            #if DEBUG
            print("📱 MainView: Showing controls")
            #endif
            resetUIControlsTimer()
        case .idle:
            break
        }
    }
    
    private func toggleUIControls() {
        uiControlsTimer?.invalidate()
        
        withAnimation(.easeOut(duration: 0.3)) {
            showUIControls.toggle()
        }
        
        if showUIControls {
            resetUIControlsTimer()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Horizontal scrollable canvas with both tabs side by side
                HStack(spacing: 0) {
                    lccPhotoTab
                        .frame(width: geometry.size.width)
                    
                    bccPhotoTab
                        .frame(width: geometry.size.width)
                }
                .offset(x: -CGFloat(selectedTab) * geometry.size.width + dragOffset)
                .allowsHitTesting(!isAnyFullScreen)
                .ignoresSafeArea(edges: [.top, .bottom, .leading, .trailing])
                .clipped()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            // Only allow horizontal dragging when not in fullscreen
                            guard fullScreenMedia == nil else { return }
                            
                            let translation = value.translation.width
                            let verticalTranslation = value.translation.height
                            
                            // Determine if this is primarily a horizontal gesture
                            // Require 3x more horizontal than vertical to activate
                            let isHorizontal = abs(translation) > abs(verticalTranslation) * 3
                            
                            // Only respond to primarily horizontal gestures
                            guard isHorizontal else { 
                                // Reset if we started horizontal but went vertical
                                if dragOffset != 0 {
                                    dragOffset = 0
                                }
                                return 
                            }
                            
                            // Add resistance at edges
                            if (selectedTab == 0 && translation > 0) || (selectedTab == 1 && translation < 0) {
                                dragOffset = translation * 0.2 // Reduced movement at edges
                            } else {
                                dragOffset = translation
                            }
                        }
                        .onEnded { value in
                            guard fullScreenMedia == nil else { return }
                            
                            let translation = value.translation.width
                            let verticalTranslation = value.translation.height
                            
                            // Check if this was primarily horizontal
                            // Require 3x more horizontal than vertical to switch tabs
                            let isHorizontal = abs(translation) > abs(verticalTranslation) * 3
                            
                            guard isHorizontal else {
                                // Not horizontal enough, just reset
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                                return
                            }
                            
                            let velocity = value.predictedEndTranslation.width - value.translation.width
                            let threshold: CGFloat = geometry.size.width * 0.25
                            let velocityThreshold: CGFloat = 400
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                if translation < -threshold || velocity < -velocityThreshold {
                                    // Swipe to BCC (right tab)
                                    if selectedTab == 0 {
                                        selectedTab = 1
#if os(iOS)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                                    }
                                } else if translation > threshold || velocity > velocityThreshold {
                                    // Swipe to LCC (left tab)
                                    if selectedTab == 1 {
                                        selectedTab = 0
#if os(iOS)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
                                    }
                                }
                                
                                // Reset drag offset
                                dragOffset = 0
                            }
                        }
                )
                .onChange(of: selectedTab) {
                    // Show controls when switching tabs
                    resetUIControlsTimer()
                }
            
            // fades moved to overlay modifiers pinned to device edges
            
            // Overlay the fullscreen media if needed
            if let presented = fullScreenMedia {
                FullScreenImageGalleryView(
                    mediaItems: currentMediaItems,
                    initialMediaItem: presented.mediaItem,
                    onDismiss: {
                        withAnimation { fullScreenMedia = nil }
                    },
                    onTabChange: nil // Do not allow tab switching from fullscreen
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .id(overlayUUID)
                .transition(.opacity)
                .zIndex(3)
            } else {

                // Removed tap shield to allow lists/grids to scroll normally
                
                // Invisible tap area at top to show controls when hidden
                if !showUIControls {
                    Color.clear
                        .frame(width: geometry.size.width, height: 100)
                        .contentShape(Rectangle())
                        .position(x: geometry.size.width / 2, y: 50)
                        .onTapGesture {
                            resetUIControlsTimer()
                        }
                        .zIndex(2.5)
                }
            }
            }
            .background(Color.black)
            .ignoresSafeArea(edges: .all)
        }
        // Top overlay menu removed (tabs moved to unified bottom bar)
        .overlay(alignment: .top) {
            // Top fade pinned to device edge
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
            .allowsHitTesting(false)
        }
        // Bottom bar now uses native toolbar for default sizing/positioning
        .toolbar {
            if fullScreenMedia == nil {
                ToolbarItem(placement: .bottomBar) {
                    UnifiedBottomBarToolbar(
                        tabs: ["LCC", "BCC"],
                        selectedTab: $selectedTab,
                        gridMode: $gridMode,
                        showConnectionDetails: $showConnectionDetails
                    )
                    .opacity(showUIControls ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: showUIControls)
                }
            }
        }
        .toolbarBackground(.visible, for: .bottomBar)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) {
            refreshImagesTrigger += 1
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshImagesTrigger += 1
            }
        }
        .onChange(of: fullScreenMedia) { _, newValue in
            isAnyFullScreen = newValue != nil
        }
        .onChange(of: showConnectionDetails) { _, isOpen in
            // When dialog closes, restart auto-hide timer
            if !isOpen {
                resetUIControlsTimer()
            } else {
                // When dialog opens, cancel auto-hide timer
                uiControlsTimer?.invalidate()
            }
        }
        .onAppear {
            // Show controls on initial load with auto-hide
            resetUIControlsTimer()
        }
        .onDisappear {
            // Clean up timer
            uiControlsTimer?.invalidate()
        }
    }
}

// Helper for blur background
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context _: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_: UIVisualEffectView, context _: Context) {}
}


struct MainViewPreview : View {
    var body: some View {
        let lccUrls = [
            "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
            "https://youtube.com/embed/dQw4w9WgXcQ",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw=="
        ]
        let bccUrls = [
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTUuanBlZw==",
            "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTYuanBlZw==",
        ]
        
        MainView(
            mediaItems: (
                lcc: lccUrls.compactMap { MediaItem.from(urlString: $0) },
                bcc: bccUrls.compactMap { MediaItem.from(urlString: $0) }
            )
        )
        .environmentObject(ImagePreloader())
    }
}

#Preview {
    MainViewPreview()
}
