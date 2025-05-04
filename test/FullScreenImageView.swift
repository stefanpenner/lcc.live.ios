import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.1
  
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