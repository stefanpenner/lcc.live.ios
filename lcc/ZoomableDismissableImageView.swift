import SwiftUI

struct ZoomableDismissableImageView: View {
    let image: UIImage
    let geometry: GeometryProxy
    let onFlickDismiss: (() -> Void)?

    @State private var scale: CGFloat = 1.1
    @State private var offset: CGSize = .zero
    @State private var isDismissing = false
    @State private var isSnappingBack = false
    @State private var isDragging = false

    var body: some View {
        let fadeThreshold: CGFloat = 50
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .scaleEffect(scale)
            .offset(offset)
            .opacity(isDismissing ? 0 : 1)
            .shadow(color: .black.opacity(0.5), radius: 32, x: 0, y: 8)
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
            .simultaneousGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        offset = value.translation
                        isDragging = true
                        isSnappingBack = false
                    }
                    .onEnded { value in
                        isDragging = false
                        let vertical = value.translation.height
                        let horizontal = value.translation.width
                        let velocity = value.predictedEndLocation.y - value.location.y
                        let isFlick = abs(velocity) > 300
                        if (abs(vertical) > fadeThreshold && abs(vertical) > abs(horizontal)) || (isFlick && abs(vertical) > abs(horizontal)) {
                            let direction: CGFloat = vertical > 0 ? 1 : -1
                            let flingDistance = direction * geometry.size.height * 1.2
                            withAnimation(.easeInOut(duration: 0.32)) {
                                offset = CGSize(width: 0, height: flingDistance)
                                isDismissing = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                                onFlickDismiss?()
                            }
                        } else {
                            isSnappingBack = true
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                            // After snap-back animation, reset isSnappingBack
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                isSnappingBack = false
                            }
                        }
                    }
            )
            .onChange(of: image) { _ in
                offset = .zero
                scale = 1.1
                isDismissing = false
                isDragging = false
                isSnappingBack = false
            }
    }
} 