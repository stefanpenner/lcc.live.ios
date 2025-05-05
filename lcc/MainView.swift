import SwiftUI

struct MainView: View {
    // TODO: hard-coded for now until we have an API
    let lccImages = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0NvbGxpbnNfU25vd19TdGFrZS5qcGc=",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNzAuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL1N1cGVyaW9yLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0hpZ2hydXN0bGVyLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL3N1Z2FyX3BlYWsuanBn",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL2NvbGxpbnNfZHRjLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hcHAucHJpc21jYW0uY29tL3B1YmxpYy9oZWxwZXJzL3JlYWx0aW1lX3ByZXZpZXcucGhwP2M9ODgmcz03MjA=",
        "https://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80OGZjMjIzYzBlZDg4NDc0ZWNjMmY4ODRiZjM5ZGU2My9tZWRpdW0=",
        "https://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80NGNmZmY0ZmYyYTIxOGExMTc4ZGJiMTA1ZDk1ODQ2YS9tZWRpdW0=",
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzU3ODA3NTRmLThkYTEtNDIyMy1hYjhhLTY3NTVkODRjYmMxMC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzYxYjI0OTBiZTEwMWMwMGI5YzQ4Mzc0Zi9zbmFwc2hvdA==",
    ]

    let bccImages = [
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTYuanBlZw==",
    ]

    @State private var selectedTab = 0
    @State private var refreshImagesTrigger = 0
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAnyFullScreen: Bool = false
    // Grid mode toggle state (now global)
    @State var gridMode: PhotoTabView.GridMode = .single
    @State private var isToggleVisible: Bool = true
    @State private var lastScrollDate: Date = .init()
    let tabBarHeight: CGFloat = 36

    private let toggleFadeDuration: Double = 0.25
    private let toggleHideDelay: Double = 1.0
    private let floatingButtonSize: CGFloat = 36
    private let floatingButtonPadding: CGFloat = 12
    private var gridIcon: String { "square.grid.2x2" }
    private var toggleAnimation: Animation { .easeInOut(duration: toggleFadeDuration) }

    // Tab info for custom tab bar
    private let tabs: [(title: String, icon: String)] = [
        ("lcc", "mountain.2"),
        ("bcc", "mountain.2"),
    ]

    @State private var fullScreenImage: PresentedImage? = nil
    @State private var overlayUUID = UUID()
    @StateObject private var preloader = ImagePreloader()

    var lccPhotoTab: some View {
        PhotoTabView(
            images: lccImages,
            title: "lcc",
            icon: "mountain.2",
            selectedTab: $selectedTab,
            tabIndex: 0,
            tabCount: 2,
            isFullScreen: $isAnyFullScreen,
            gridMode: $gridMode,
            onRequestFullScreen: { image in
                overlayUUID = UUID()
                fullScreenImage = image
            },
            preloader: preloader
        )
        .tag(0)
    }

    var bccPhotoTab: some View {
        PhotoTabView(
            images: bccImages,
            title: "bcc",
            icon: "mountain.2",
            selectedTab: $selectedTab,
            tabIndex: 1,
            tabCount: 2,
            isFullScreen: $isAnyFullScreen,
            gridMode: $gridMode,
            onRequestFullScreen: { image in
                overlayUUID = UUID()
                fullScreenImage = image
            },
            preloader: preloader
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
            .ignoresSafeArea(edges: .top)

            // Top gradient overlay (at the very top, Photos app style)
            VStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground).opacity(0.95),
                        Color(.systemBackground).opacity(0.7),
                        Color(.systemBackground).opacity(0.0)
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
                FullScreenImageView(url: presented.url, preloader: preloader) {
                    withAnimation { fullScreenImage = nil }
                }
                .id(overlayUUID)
                .transition(.opacity)
                .zIndex(3)
            } else {
                // Bottom floating GridModeToggle
                VStack {
                    Spacer()
                    GridModeToggle(
                        gridMode: $gridMode,
                        toggleAnimation: toggleAnimation,
                        floatingButtonSize: floatingButtonSize,
                        floatingButtonPadding: floatingButtonPadding,
                        gridIcon: gridIcon
                    )
                    .padding(.bottom, 8)
                }
                .zIndex(2)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if fullScreenImage == nil {
                ModernTabBar(
                    tabs: tabs,
                    selectedTab: $selectedTab
                )
                .frame(height: tabBarHeight)
                .padding(.top, 4)
                .zIndex(2)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: selectedTab) { _ in
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

#Preview {
    MainView()
}
