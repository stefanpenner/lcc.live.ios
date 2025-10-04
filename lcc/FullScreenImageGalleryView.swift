import SwiftUI

struct FullScreenImageGalleryView: View {
    let images: [String]
    let initialURL: URL
    let onDismiss: () -> Void
    
    @EnvironmentObject var preloader: ImagePreloader
    @State private var currentIndex: Int = 0
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    
    init(images: [String], initialURL: URL, onDismiss: @escaping () -> Void) {
        self.images = images
        self.initialURL = initialURL
        self.onDismiss = onDismiss
        
        // Find the initial index
        if let index = images.firstIndex(where: { URL(string: $0) == initialURL }) {
            _currentIndex = State(initialValue: index)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .opacity(0.95)
                    .edgesIgnoringSafeArea(.all)
                
                // Image carousel
                HStack(spacing: 0) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, imageUrlString in
                        if let url = URL(string: imageUrlString) {
                            ZStack {
                                if let image = preloader.loadedImages[url] {
                                    ZoomableDismissableImageView(
                                        image: image,
                                        geometry: geometry,
                                        onFlickDismiss: onDismiss
                                    )
                                } else if preloader.loading.contains(url) {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("Image failed to load")
                                            .foregroundColor(.white.opacity(0.7))
                                        Button("Retry") {
                                            preloader.retryImage(for: url)
                                        }
                                        .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .offset(x: -CGFloat(currentIndex) * geometry.size.width + offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            offset = value.translation.width
                        }
                        .onEnded { value in
                            isDragging = false
                            let threshold: CGFloat = geometry.size.width * 0.2
                            
                            if value.translation.width > threshold && currentIndex > 0 {
                                // Swipe right - go to previous
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentIndex -= 1
                                    offset = 0
                                }
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            } else if value.translation.width < -threshold && currentIndex < images.count - 1 {
                                // Swipe left - go to next
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentIndex += 1
                                    offset = 0
                                }
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    offset = 0
                                }
                            }
                        }
                )
                
                // Page indicator
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: 34, height: 34)
                                )
                        }
                        .padding()
                        .accessibilityLabel("Close")
                        .accessibilityHint("Dismiss full screen view")
                    }
                    Spacer()
                }
                
                // Counter
                VStack {
                    Text("\(currentIndex + 1) of \(images.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.4))
                        )
                        .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .statusBar(hidden: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Image \(currentIndex + 1) of \(images.count)")
        .accessibilityHint("Swipe left or right to navigate between images")
    }
}

