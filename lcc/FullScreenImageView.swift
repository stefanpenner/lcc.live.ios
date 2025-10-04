import SwiftUI
import UIKit

struct FullScreenImageView: View {
    let url: URL
    @EnvironmentObject var preloader: ImagePreloader
    var onFlickDismiss: (() -> Void)? = nil

    @State private var scale: CGFloat = 1.1
    @State private var offset: CGSize = .zero
    @State private var isDismissing = false
    @State private var isSnappingBack = false
    @State private var isDragging = false

    var body: some View {
        // Background logic:
        // - While dragging: fixed moderate opacity
        // - Snapping back: animate to dark
        // - Dismissing: fade out
        let backgroundOpacity: Double = isDismissing ? 0 : (isDragging ? 0.6 : (isSnappingBack ? 0.85 : 0.85))

        GeometryReader { geometry in
            ZStack {
                Color.black
                    .opacity(backgroundOpacity)
                    .edgesIgnoringSafeArea(.all)

                Group {
                    if let image = preloader.loadedImages[url] {
                        ZoomableDismissableImageView(image: image, geometry: geometry, onFlickDismiss: onFlickDismiss)
                    } else if preloader.loading.contains(url) {
                        ProgressView()
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    } else {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Image failed to load")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onFlickDismiss?()
            }
        }

        EscapeKeyHandler {
            onFlickDismiss?()
        }
        .frame(width: 0, height: 0)
        .statusBar(hidden: true)
        .onChange(of: preloader.loadedImages[url]) {
            offset = .zero
            scale = 1.1
            isDismissing = false
            isDragging = false
            isSnappingBack = false
        }
    }
}

private struct EscapeKeyHandler: UIViewRepresentable {
    var onEscape: () -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        context.coordinator.onEscape = onEscape
        view.addSubview(context.coordinator.dummy)
        return view
    }

    func updateUIView(_: UIView, context _: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject {
        var onEscape: (() -> Void)?
        let dummy = DummyResponder()
        override init() {
            super.init()
            dummy.coordinator = self
        }

        class DummyResponder: UIView {
            weak var coordinator: Coordinator?
            override var canBecomeFirstResponder: Bool { true }
            override func didMoveToWindow() {
                super.didMoveToWindow()
                becomeFirstResponder()
            }

            override var keyCommands: [UIKeyCommand]? {
                [UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(handleEscape))]
            }

            @objc func handleEscape() {
                coordinator?.onEscape?()
            }
        }
    }
}

#Preview {
    // Mock image and preloader for preview
    class MockPreloader: ImagePreloader {
        override init() {
            super.init()
            _ = URL(string: "https://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80OGZjMjIzYzBlZDg4NDc0ZWNjMmY4ODRiZjM5ZGU2My9tZWRpdW0=")!
        }
    }
    let url = URL(string: "hhttps://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80OGZjMjIzYzBlZDg4NDc0ZWNjMmY4ODRiZjM5ZGU2My9tZWRpdW0=")!
    let preloader = MockPreloader()
    
    return FullScreenImageView(
        url: url,
        onFlickDismiss: {}
    )
    .environmentObject(preloader)
}

#Preview("missing image") {
    // Mock image and preloader for preview
    class MockPreloader: ImagePreloader {
        override init() {
            super.init()
            _ = URL(string: "https://example.com/missing.jpg")!
        }
    }
    let url = URL(string: "https://example.com/missing.jpg")!
    let preloader = MockPreloader()

    return FullScreenImageView(
        url: url,
        onFlickDismiss: {}
    )
    .environmentObject(preloader)
}
