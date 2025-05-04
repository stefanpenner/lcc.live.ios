import SwiftUI
import UIKit

struct FullScreenImageView: View {
    let url: URL
    @ObservedObject var preloader: ImagePreloader
    var onFlickDismiss: (() -> Void)? = nil

    @State private var scale: CGFloat = 1.1
    @State private var offset: CGSize = .zero
    @State private var isDismissing = false
    @State private var isSnappingBack = false
    @State private var isDragging = false

    var body: some View {
        let fadeThreshold: CGFloat = 50
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
        .onChange(of: preloader.loadedImages[url]) { _ in
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
