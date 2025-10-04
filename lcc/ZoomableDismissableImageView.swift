import SwiftUI

struct ZoomableDismissableImageView: View {
    let image: UIImage
    let geometry: GeometryProxy
    let onFlickDismiss: (() -> Void)?
    var onZoomChanged: ((Bool) -> Void)? = nil

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDismissing = false
    @State private var isSnappingBack = false
    @State private var isDragging = false
    @State private var currentMagnification: CGFloat = 1.0

    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 4.0

    var body: some View {
        let fadeThreshold: CGFloat = 50
        let isZoomed = scale > 1.01
        
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .scaleEffect(scale)
            .offset(offset)
            .opacity(isDismissing ? 0 : 1)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        // Update scale in real-time
                        let newScale = lastScale * value
                        scale = min(max(newScale, minZoom), maxZoom)
                    }
                    .onEnded { value in
                        // Finalize the scale
                        let newScale = lastScale * value
                        let finalScale = min(max(newScale, minZoom), maxZoom)
                        
                        // If zoomed out to min, reset offset with animation
                        if finalScale <= minZoom {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scale = minZoom
                                offset = .zero
                            }
                            lastOffset = .zero
                        } else {
                            // Constrain offset to bounds
                            let constrainedOffset = constrainOffset(offset, scale: finalScale)
                            if constrainedOffset != offset {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = constrainedOffset
                                }
                            }
                            lastOffset = offset
                        }
                        
                        lastScale = scale
                        onZoomChanged?(scale > 1.01)
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: isZoomed ? 0 : 10, coordinateSpace: .local)
                    .onChanged { value in
                        isDragging = true
                        isSnappingBack = false
                        
                        if isZoomed {
                            // When zoomed, allow panning the image
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            offset = constrainOffset(newOffset, scale: scale)
                        } else {
                            // When not zoomed, allow vertical dismiss gesture
                            offset = value.translation
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        if isZoomed {
                            // When zoomed, just save the final position
                            lastOffset = offset
                        } else {
                            // When not zoomed, handle dismiss gesture
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
                                    lastOffset = .zero
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    isSnappingBack = false
                                }
                            }
                        }
                    }
            )
            .onTapGesture(count: 2) {
                // Double tap to zoom in/out
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if scale > 1.01 {
                        // Zoom out
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        // Zoom in to 2x
                        scale = 2.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
                lastScale = scale
                onZoomChanged?(scale > 1.01)
            }
            .onChange(of: image) {
                // Preserve zoom level but recalculate valid offset bounds for new image
                if scale > 1.0 {
                    // Constrain offset to the new image's bounds
                    offset = constrainOffset(offset, scale: scale)
                    lastOffset = offset
                    // Notify parent that zoom is still active
                    onZoomChanged?(true)
                } else {
                    offset = .zero
                    lastOffset = .zero
                    onZoomChanged?(false)
                }
                // Note: scale and lastScale are preserved
                isDismissing = false
                isDragging = false
                isSnappingBack = false
            }
    }
    
    // Constrain offset to prevent panning beyond image bounds when zoomed
    private func constrainOffset(_ offset: CGSize, scale: CGFloat) -> CGSize {
        guard scale > 1.0 else { return .zero }
        
        // Calculate the size of the image at current scale
        let imageSize = calculateImageSize()
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        // Calculate maximum allowed offset
        let maxOffsetX = max(0, (scaledWidth - geometry.size.width) / 2)
        let maxOffsetY = max(0, (scaledHeight - geometry.size.height) / 2)
        
        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }
    
    private func calculateImageSize() -> CGSize {
        let imageAspect = image.size.width / image.size.height
        let viewAspect = geometry.size.width / geometry.size.height
        
        if imageAspect > viewAspect {
            // Image is wider - fit to width
            let width = geometry.size.width
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        } else {
            // Image is taller - fit to height
            let height = geometry.size.height
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ZoomableDismissableImageView(
            image: UIImage(systemName: "photo")!.withRenderingMode(.alwaysTemplate),
            geometry: geometry,
            onFlickDismiss: {}
        )
    }
}
