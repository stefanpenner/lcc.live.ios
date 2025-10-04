import Combine
import Foundation
import SwiftUI

struct PhotoTabView: View {
    let images: [String]
    
    @Binding public var gridMode: GridMode
    var onRequestFullScreen: (PresentedImage) -> Void
    @EnvironmentObject var preloader: ImagePreloader

    @Environment(\.colorScheme) var colorScheme

    // User grid mode
    public enum GridMode: String, CaseIterable, Identifiable {
        case compact = "Compact"
        case single = "Single"
        var id: String { rawValue }
    }

    private let spacing: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (spacing * 1)
            let columns = gridMode == .single ? 1 : max(1, Int(availableWidth / 180))
            let imageWidth = (availableWidth - CGFloat(columns - 1) * 5) / CGFloat(columns)
            let imageHeight = imageWidth * (gridMode == .single ? 0.9 : 0.9)
            let gridItems = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: columns)
            
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 60)
                    LazyVGrid(columns: gridItems, spacing: spacing) {
                        ForEach(images, id: \.self) { imageUrl in
                            PhotoCell(
                                imageUrl: imageUrl,
                                imageWidth: imageWidth,
                                imageHeight: imageHeight,
                                colorScheme: colorScheme,
                                onTap: {
                                    if let url = URL(string: imageUrl), preloader.loadedImages[url] != nil {
                                        onRequestFullScreen(PresentedImage(url: url))
                                    }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            preloader.preloadImages(from: images)
            preloader.refreshImages()
        }
    }
}

private struct PhotoCell: View {
    let imageUrl: String
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let colorScheme: ColorScheme
    let onTap: () -> Void

    @EnvironmentObject var preloader: ImagePreloader

    var body: some View {
        let url = URL(string: imageUrl)!
        let loadedImage = preloader.loadedImages[url]
        
        ZStack(alignment: .top) {
            Group {
                if let uiImage = loadedImage {
                    // Show preloaded image
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .onTapGesture {
                            onTap()
                        }
                } else if preloader.loading.contains(url) {
                    // Show loading state
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
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    // Show error state
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(Color.gray.opacity(0.8))
                        Text("Could not load image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: imageWidth, height: imageHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark ?
                                        [Color(red: 0.18, green: 0.13, blue: 0.13), Color(red: 0.22, green: 0.16, blue: 0.18)] :
                                        [Color(red: 0.99, green: 0.95, blue: 0.92), Color(red: 0.95, green: 0.92, blue: 0.99)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Subtle border while updating
            let isLoading = preloader.loading.contains(url)
            let fadeDate = preloader.fadingOut[url]
            let isFadingOut = fadeDate != nil
            let fadeProgress: CGFloat = {
                guard let fadeDate = fadeDate else { return 0 }
                let elapsed = CGFloat(Date().timeIntervalSince(fadeDate))
                let duration: CGFloat = 3.0
                return min(1, max(0, elapsed / duration))
            }()
            let borderOpacity: CGFloat = isFadingOut ? (1 - fadeProgress) : (isLoading ? 0.3 : 0)
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accentColor.opacity(0.60), lineWidth: 4)
                .frame(width: imageWidth, height: imageHeight)
                .opacity(borderOpacity)
                .animation(.easeInOut(duration: 0.4), value: borderOpacity)
        }
       
    }
}

struct PresentedImage: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

#Preview {
    let preloader = ImagePreloader()
    let images = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw=="
    ]
    
    // Preload images immediately for preview
    preloader.preloadImages(from: images)
    
    return PhotoTabView(
        images: images,
        gridMode: .constant(PhotoTabView.GridMode.single),
        onRequestFullScreen: { _ in })
    .environmentObject(preloader)
}

#Preview("With Mock Images") {
    // Mock preloader with sample images already loaded
    class MockImagePreloader: ImagePreloader {
        override init() {
            super.init()
            // Add some mock images to simulate loaded state
            if let sampleImage = UIImage(systemName: "photo.fill") {
                let urls = [
                    "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
                    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw=="
                ].compactMap { URL(string: $0) }
                
                for url in urls {
                    self.loadedImages[url] = sampleImage
                }
            }
        }
    }
    
    let images = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw=="
    ]
    
    return PhotoTabView(
        images: images,
        gridMode: .constant(PhotoTabView.GridMode.compact),
        onRequestFullScreen: { _ in })
    .environmentObject(MockImagePreloader())
}
