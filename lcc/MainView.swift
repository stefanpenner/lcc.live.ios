import SwiftUI

struct MainView: View {
    enum Tab: Hashable {
        case lcc, bcc
        
        @ViewBuilder
        var label: some View {
            switch self {
            case .lcc:
                Label("LCC", systemImage: "mountain.2")
            case .bcc:
                Label("BCC", systemImage: "mountain.2")
            }
        }
    }
    
    let mediaItems: (lcc: [MediaItem], bcc: [MediaItem])
    @EnvironmentObject var preloader: ImagePreloader
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var apiService: APIService

    @State private var selectedTab: Tab = .lcc
    @State private var refreshImagesTrigger = 0
    @Environment(\.scenePhase) private var scenePhase
    @State private var gridMode: PhotoTabView.GridMode = .single
    @State private var fullScreenMedia: PresentedMedia? = nil
    @State private var showConnectionDetails = false
    
    private var currentMediaItems: [MediaItem] {
        selectedTab == .lcc ? mediaItems.lcc : mediaItems.bcc
    }
    
    private var statusColor: Color {
        ConnectionStatusHelper.statusColor(
            isConnected: networkMonitor.isConnected,
            hasError: apiService.error != nil,
            isLoading: apiService.isLoading
        )
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // LCC Tab
            PhotoTabView(
                mediaItems: mediaItems.lcc,
                gridMode: $gridMode,
                onRequestFullScreen: { media in
                    fullScreenMedia = media
                }
            )
            .tabItem { Tab.lcc.label }
            .tag(Tab.lcc)
            
            // BCC Tab
            PhotoTabView(
                mediaItems: mediaItems.bcc,
                gridMode: $gridMode,
                onRequestFullScreen: { media in
                    fullScreenMedia = media
                }
            )
            .tabItem { Tab.bcc.label }
            .tag(Tab.bcc)
        }
        .background(Color.black)
        .overlay(alignment: .top) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.black.opacity(0.7), location: 0.0),
                    .init(color: Color.black.opacity(0.35), location: 0.22),
                    .init(color: Color.clear, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: 140)
            .ignoresSafeArea(edges: [.top, .leading, .trailing])
            .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            if fullScreenMedia == nil {
                Button {
                    showConnectionDetails.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)
                            .shadow(color: statusColor.opacity(0.6), radius: 4)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .popover(isPresented: $showConnectionDetails) {
                    ConnectionDetailsView()
                        .presentationCompactAdaptation(.popover)
                }
                .padding(.top, 60)
                .padding(.leading, 16)
            }
        }
        .overlay(alignment: .topTrailing) {
            if fullScreenMedia == nil {
                Button {
                    withAnimation {
                        gridMode = gridMode == .single ? .compact : .single
                    }
                } label: {
                    Image(systemName: gridMode == .single ? "square.grid.2x2" : "rectangle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.top, 60)
                .padding(.trailing, 16)
            }
        }
        .fullScreenCover(item: $fullScreenMedia) { presented in
            GalleryFullScreenView(
                items: currentMediaItems,
                initialIndex: currentMediaItems.firstIndex(where: { $0.url == presented.mediaItem.url }) ?? 0,
                onClose: { fullScreenMedia = nil }
            )
        }
        .onChange(of: selectedTab) { refreshImagesTrigger += 1 }
        .onChange(of: scenePhase) { _, newPhase in if newPhase == .active { refreshImagesTrigger += 1 } }
    }
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
        .environmentObject(NetworkMonitor.shared)
        .environmentObject(APIService())
    }
}

#Preview {
    MainViewPreview()
}

