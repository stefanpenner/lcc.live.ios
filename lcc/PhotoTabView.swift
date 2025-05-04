import SwiftUI

struct PhotoTabView: View {
    let images: [String]
    let title: String
    let icon: String
    var refreshImagesTrigger: Int = 0 // default for backward compatibility

    @StateObject private var preloader = ImagePreloader()
    @Environment(\.colorScheme) var colorScheme

    // Layout constants
    private let minImageWidth: CGFloat = 340
    private let spacing: CGFloat = 20

    // Use optional PresentedImage for full screen state
    @State private var fullScreenImage: PresentedImage? = nil
    @State private var overlayUUID = UUID()
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width - (spacing * 2)
                let maxColumns = max(1, Int(availableWidth / minImageWidth))
                let imageWidth = max(minImageWidth, (availableWidth - (spacing * CGFloat(maxColumns - 1))) / CGFloat(maxColumns))
                let imageHeight = imageWidth * 0.6
                let columns = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: maxColumns)

                VStack(alignment: .leading, spacing: 8) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Show only when pulling to refresh
                            if isRefreshing {
                                Text("Last refreshed: \(preloader.lastRefreshed, formatter: dateFormatter)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            LazyVGrid(columns: columns, spacing: spacing) {
                                ForEach(images, id: \.self) { imageUrl in
                                    PhotoCell(
                                        imageUrl: imageUrl,
                                        preloadedImage: preloader.loadedImages[URL(string: imageUrl) ?? URL(fileURLWithPath: "")],
                                        imageWidth: imageWidth,
                                        imageHeight: imageHeight,
                                        colorScheme: colorScheme,
                                        onTap: { _ in
                                            if let url = URL(string: imageUrl) {
                                                overlayUUID = UUID()
                                                fullScreenImage = PresentedImage(url: url)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    .refreshable {
                        await MainActor.run { isRefreshing = true }
                        preloader.refreshImages()
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run { isRefreshing = false }
                    }
                }
            }
            // Overlay the fullscreen image if needed
            if let presented = fullScreenImage {
                FullScreenImageView(url: presented.url, preloader: preloader) {
                    withAnimation { fullScreenImage = nil }
                }
                .id(overlayUUID)
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut, value: fullScreenImage)
        .onAppear {
            preloader.preloadImages(from: images)
            preloader.refreshImages()
        }
        .onChange(of: refreshImagesTrigger) { _ in
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

    var body: some View {
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
    }
}

// For .fullScreenCover(item:) to work with URL
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
