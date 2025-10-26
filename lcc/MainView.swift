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
    // Removed manual UI controls hiding/showing; rely on system defaults
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
            onScrollActivity: { },
            onScrollDirectionChanged: { _ in }
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
            onScrollActivity: { },
            onScrollDirectionChanged: { _ in }
        )
        .tag(1)
    }
    
    // Removed resetUIControlsTimer
    
    // Removed handleScrollDirection
    
    // Removed toggleUIControls
    
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
            
            // fades moved to overlay modifiers pinned to device edges
            
            // Fullscreen overlay moved to .fullScreenCover
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
                    Picker("", selection: $selectedTab) {
                        Text("LCC").tag(0)
                        Text("BCC").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Picker("", selection: $gridMode) {
                            Image(systemName: "square.grid.2x2").tag(PhotoTabView.GridMode.compact)
                            Image(systemName: "rectangle.fill").tag(PhotoTabView.GridMode.single)
                        }
                        .pickerStyle(.segmented)

                        ConnectionStatusView(showDetails: $showConnectionDetails)
                    }
                }
            }
        }
        .toolbarBackground(.visible, for: .bottomBar)
        .fullScreenCover(item: $fullScreenMedia) { presented in
            GalleryFullScreenView(
                items: currentMediaItems,
                initialIndex: currentMediaItems.firstIndex(where: { $0.url == presented.mediaItem.url }) ?? 0,
                onClose: { fullScreenMedia = nil }
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) { refreshImagesTrigger += 1 }
        .onChange(of: scenePhase) { _, newPhase in if newPhase == .active { refreshImagesTrigger += 1 } }
        .onChange(of: fullScreenMedia) { _, newValue in isAnyFullScreen = newValue != nil }
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
