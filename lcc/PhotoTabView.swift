import Combine
import Foundation
import SwiftUI

struct PhotoTabView: View {
    let images: [String]
    let title: String
    let icon: String
    @Binding var selectedTab: Int
    let tabIndex: Int
    let tabCount: Int
    @Binding var isFullScreen: Bool
    @Binding public var gridMode: GridMode
    var onRequestFullScreen: (PresentedImage) -> Void
    var preloader: ImagePreloader
    let topContentInset: CGFloat

    @Environment(\.colorScheme) var colorScheme

    // User grid mode
    public enum GridMode: String, CaseIterable, Identifiable {
        case compact = "Compact"
        case single = "Single"
        var id: String { rawValue }
    }

    private let spacing: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (spacing * 2)
            let columns = gridMode == .single ? 1 : max(1, Int(availableWidth / 180))
            let imageWidth = (availableWidth - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            let imageHeight = imageWidth * (gridMode == .single ? 0.7 : 0.8)
            let gridItems = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: columns)
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: spacing) {
                    ForEach(images, id: \.self) { imageUrl in
                        PhotoCell(
                            imageUrl: imageUrl,
                            preloadedImage: preloader.loadedImages[URL(string: imageUrl) ?? URL(fileURLWithPath: "")],
                            imageWidth: imageWidth,
                            imageHeight: imageHeight,
                            colorScheme: colorScheme,
                            onTap: { _ in
                                if let url = URL(string: imageUrl), preloader.loadedImages[url] != nil {
                                    onRequestFullScreen(PresentedImage(url: url))
                                }
                            }
                        )
                        .environmentObject(preloader)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, topContentInset)
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height
                    if abs(horizontalAmount) > abs(verticalAmount) * 1.5 {
                        if horizontalAmount < -50, tabIndex < tabCount - 1 {
                            selectedTab = tabIndex + 1
                        } else if horizontalAmount > 50, tabIndex > 0 {
                            selectedTab = tabIndex - 1
                        }
                    }
                }
        )
        .onAppear {
            preloader.preloadImages(from: images)
            preloader.refreshImages()
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
}

private struct PhotoCell: View {
    let imageUrl: String
    let preloadedImage: UIImage?
    let imageWidth: CGFloat
    let imageHeight: CGFloat
    let colorScheme: ColorScheme
    let onTap: (UIImage) -> Void
    @EnvironmentObject var preloader: ImagePreloader

    var body: some View {
        let url = URL(string: imageUrl) ?? URL(fileURLWithPath: "")
        let isLoading = preloader.loading.contains(url)
        let fadeDate = preloader.fadingOut[url]
        let isFadingOut = fadeDate != nil
        let fadeProgress: CGFloat = {
            guard let fadeDate = fadeDate else { return 0 }
            let elapsed = CGFloat(Date().timeIntervalSince(fadeDate))
            let duration: CGFloat = 3.0
            return min(1, max(0, elapsed / duration))
        }()
        ZStack(alignment: .top) {
            Group {
                if let image = preloadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(image) }
                } else {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
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
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageWidth, height: imageHeight)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
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
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: imageWidth, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            // Subtle border while updating
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

// DateFormatter for last refreshed
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()
