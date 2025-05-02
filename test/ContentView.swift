//
//  ContentView.swift
//  test
//
//  Created by Stefan Penner on 4/30/25.
//

import SwiftUI

struct PhotoTabView: View {
    let images: [String]
    let title: String
    let icon: String
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let columns = [
                GridItem(.flexible(), spacing: 20),
                isLandscape ? GridItem(.flexible(), spacing: 20) : nil
            ].compactMap { $0 }
            
            let imageWidth = min(max(geometry.size.width * 0.95, 340), 600)
            let imageHeight = imageWidth * 0.6
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(images, id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: imageWidth, height: imageHeight)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.96, green: 0.89, blue: 0.90),
                                                     Color(red: 0.85, green: 0.89, blue: 0.96)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: imageWidth, height: imageHeight)
                                    .clipped()
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: imageWidth, height: imageHeight)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.96, green: 0.89, blue: 0.90),
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
            }
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
}

struct ContentView: View {
    // Web image URLs
    let lccImages = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0NvbGxpbnNfU25vd19TdGFrZS5qcGc=",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw=="
    ]
    
    let bccImages = [
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw=="
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
