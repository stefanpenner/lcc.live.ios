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
        // Show controls when any scroll activity detected
        withAnimation(.easeOut(duration: 0.3)) {
            showUIControls = true
        }
    }
    
    private func handleScrollDirection(_ direction: PhotoTabView.ScrollDirection) {
        withAnimation(.easeOut(duration: 0.3)) {
            switch direction {
            case .down:
                // Scrolling down - hide controls
                showUIControls = false
            case .up:
                // Scrolling up - show controls
                showUIControls = true
            case .idle:
                break
            }
        }
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                lccPhotoTab
                bccPhotoTab
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .allowsHitTesting(!isAnyFullScreen)
            .ignoresSafeArea(edges: [.top, .bottom])
            .onChange(of: selectedTab) {
#if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif
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
