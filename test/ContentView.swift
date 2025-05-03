//
//  ContentView.swift
//  test
//
//  Created by Stefan Penner on 4/30/25.
//

import SwiftUI

class ImagePreloader: ObservableObject {
    @Published var loadedImages: [URL: UIImage] = [:]
    
    func preloadImages(from urls: [String]) {
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, let image = UIImage(data: data) else {
                    print("Failed to load image from URL: \(urlString)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.loadedImages[url] = image
                    print("Successfully loaded image: \(urlString)")
                }
            }.resume()
        }
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismiss()
                    }
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                            .onEnded { _ in
                                withAnimation {
                                    scale = 1.0
                                }
                            }
                    )
                    .onAppear {
                        print("FullScreenImageView appeared with image size: \(image.size)")
                        print("Geometry size: \(geometry.size)")
                    }
            }
        }
        .overlay(
            Button(action: {
                print("Dismiss button tapped")
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
                    .padding()
            }
            .padding()
            , alignment: .topTrailing
        )
        .statusBar(hidden: true)
    }
}

struct PhotoTabView: View {
    let images: [String]
    let title: String
    let icon: String
    
    @StateObject private var preloader = ImagePreloader()
    @Environment(\.colorScheme) var colorScheme
    
    enum FullScreenState {
        case hidden
        case showing(UIImage)
    }
    
    @State private var fullScreenState: FullScreenState = .hidden
    
    var body: some View {
        GeometryReader { geometry in
            let minImageWidth: CGFloat = 340
            let spacing: CGFloat = 20
            let availableWidth = geometry.size.width - (spacing * 2)
            
            let maxColumns = max(1, Int(availableWidth / minImageWidth))
            let imageWidth = max(minImageWidth, (availableWidth - (spacing * CGFloat(maxColumns - 1))) / CGFloat(maxColumns))
            let imageHeight = imageWidth * 0.6
            
            let columns = Array(repeating: GridItem(.fixed(imageWidth), spacing: spacing), count: maxColumns)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(images, id: \.self) { imageUrl in
                        if let url = URL(string: imageUrl),
                           let preloadedImage = preloader.loadedImages[url] {
                            Image(uiImage: preloadedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageWidth, height: imageHeight)
                                .clipped()
                                .frame(width: imageWidth, height: imageHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    fullScreenState = .showing(preloadedImage)
                                }
                        } else {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: imageWidth, height: imageHeight)
                                        .background(
                                            LinearGradient(
                                                colors: colorScheme == .dark ? 
                                                    [Color(red: 0.1, green: 0.1, blue: 0.15),
                                                     Color(red: 0.15, green: 0.15, blue: 0.2)] :
                                                    [Color(red: 0.96, green: 0.89, blue: 0.90),
                                                     Color(red: 0.85, green: 0.89, blue: 0.96)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                case .success(let image):
                                    EmptyView()
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: imageWidth, height: imageHeight)
                                        .background(
                                            LinearGradient(
                                                colors: colorScheme == .dark ? 
                                                    [Color(red: 0.1, green: 0.1, blue: 0.15),
                                                     Color(red: 0.15, green: 0.15, blue: 0.2)] :
                                                    [Color(red: 0.96, green: 0.89, blue: 0.90),
                                                     Color(red: 0.85, green: 0.89, blue: 0.96)],
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
                .padding()
            }
        }
        .onAppear {
            print("PhotoTabView appeared, starting to preload \(images.count) images")
            preloader.preloadImages(from: images)
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
        .fullScreenCover(isPresented: Binding(
            get: {
                if case .showing = fullScreenState {
                    return true
                }
                return false
            },
            set: { newValue in
                if !newValue {
                    fullScreenState = .hidden
                }
            }
        )) {
            if case .showing(let image) = fullScreenState {
                FullScreenImageView(image: image)
            }
        }
    }
}

struct ContentView: View {
    // Web image URLs
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
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzYxYjI0OTBiZTEwMWMwMGI5YzQ4Mzc0Zi9zbmFwc2hvdA=="
    ]
    
    let bccImages = [
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTYuanBlZw=="
    ]
    
    var body: some View {
        TabView {
            PhotoTabView(images: lccImages, title: "lcc", icon: "leaf")
            PhotoTabView(images: bccImages, title: "bcc", icon: "flame")
        }
        .tabViewStyle(.automatic)
    }
}

#Preview {
    ContentView()
}
