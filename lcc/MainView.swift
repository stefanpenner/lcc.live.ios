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
        
        // Auto-hide after 3 seconds of no activity
        uiControlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                showUIControls = false
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
                .ignoresSafeArea(edges: [.top, .bottom])
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            // Only allow horizontal dragging when not in fullscreen
                            guard fullScreenMedia == nil else { return }
                            
                            let translation = value.translation.width
                            let verticalTranslation = abs(value.translation.height)
                            
                            // Only respond to primarily horizontal gestures
                            guard abs(translation) > verticalTranslation * 1.5 else { return }
                            
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
            
            // Top gradient overlay (at the very top, Photos app style)
            if fullScreenMedia == nil {
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground).opacity(0.95),
                            Color(.systemBackground).opacity(0.7),
                            Color(.systemBackground).opacity(0.0),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .zIndex(1.5)
                .opacity(showUIControls ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: showUIControls)
                .allowsHitTesting(false) // Don't intercept touches - let them pass through to buttons
            }
            
            // Overlay the fullscreen media if needed
            if let presented = fullScreenMedia {
                FullScreenImageGalleryView(
                    mediaItems: currentMediaItems,
                    initialMediaItem: presented.mediaItem,
                    onDismiss: {
                        withAnimation { fullScreenMedia = nil }
                    },
                    onTabChange: { newTab in
                        #if DEBUG
                        print("🔄 MainView: Tab change from fullscreen: \(newTab)")
                        #endif
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                            selectedTab = newTab
                        }
                    }
                )
                .id(overlayUUID)
                .transition(.opacity)
                .zIndex(3)
            } else {
                // Bottom floating GridModeToggle
                VStack {
                    Spacer()
                    GridModeToggle(
                        gridMode: $gridMode,
                    )
                    .padding(.bottom, 8)
                    .opacity(showUIControls ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: showUIControls)
                }
                .zIndex(2)
                
                // Invisible tap area at top to show controls when hidden
                if !showUIControls {
                    VStack {
                        Color.clear
                            .frame(height: 100)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                resetUIControlsTimer()
                            }
                        Spacer()
                    }
                    .zIndex(2.5)
                }
            }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if fullScreenMedia == nil {
                ModernTabBar(
                    tabs: ["LCC", "BCC"],
                    selectedTab: $selectedTab
                )
                .frame(height: tabBarHeight)
                .padding(.top, isLandscape ? 12 : 4)
                .zIndex(10) // High zIndex to ensure it's above gradient
                .opacity(showUIControls ? 1 : 0)
                .offset(y: showUIControls ? 0 : -10)
                .animation(.easeOut(duration: 0.3), value: showUIControls)
            }
        }
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
