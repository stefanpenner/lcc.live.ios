import SwiftUI

struct MainView: View {
    let images: (lcc: [String], bcc: [String])
    @EnvironmentObject var preloader: ImagePreloader

    @State private var selectedTab = 0
    @State private var refreshImagesTrigger = 0
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAnyFullScreen: Bool = false
    @State private var gridMode: PhotoTabView.GridMode = .single
    let tabBarHeight: CGFloat = 36
    
    @State private var fullScreenImage: PresentedImage? = nil
    @State private var overlayUUID = UUID()
    
    private var currentImages: [String] {
        selectedTab == 0 ? images.lcc : images.bcc
    }
    
    var lccPhotoTab: some View {
        PhotoTabView(
            images: images.lcc,
            gridMode: $gridMode,
            onRequestFullScreen: { image in
                overlayUUID = UUID()
                fullScreenImage = image
            }
        )
        .tag(0)
    }
    
    var bccPhotoTab: some View {
        PhotoTabView(
            images: images.bcc,
            gridMode: $gridMode,
            onRequestFullScreen: { image in
                overlayUUID = UUID()
                fullScreenImage = image
            }
        )
        .tag(1)
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
            
            // Overlay the fullscreen image if needed
            if let presented = fullScreenImage {
                FullScreenImageGalleryView(
                    images: currentImages,
                    initialURL: presented.url,
                    onDismiss: {
                        withAnimation { fullScreenImage = nil }
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
                }
                .zIndex(2)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if fullScreenImage == nil {
                ModernTabBar(
                    tabs: ["LCC", "BCC"],
                    selectedTab: $selectedTab
                )
                .frame(height: tabBarHeight)
                .padding(.top, 4)
                .zIndex(2)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) {
            refreshImagesTrigger += 1
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                refreshImagesTrigger += 1
            }
        }
        .onChange(of: fullScreenImage) { newValue in
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
        MainView(
            images: (
                lcc: [
                    "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw=="
                ],
                bcc: [
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTUuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTYuanBlZw==",
                ]
            )
        )
        .environmentObject(ImagePreloader())
    }
}

#Preview {
    MainViewPreview()
}
