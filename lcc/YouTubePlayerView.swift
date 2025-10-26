import SwiftUI
import WebKit

/// A view that displays YouTube videos using WKWebView
struct YouTubePlayerView: UIViewRepresentable {
    let embedURL: String
    let autoplay: Bool
    
    init(embedURL: String, autoplay: Bool = false) {
        self.embedURL = embedURL
        self.autoplay = autoplay
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []  // Allow autoplay
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Use youtube-nocookie.com domain for better compatibility and privacy
        var urlString = embedURL.replacingOccurrences(of: "youtube.com", with: "youtube-nocookie.com")
        
        // Build parameters
        var params: [String] = []
        
        // Autoplay
        if autoplay {
            params.append("autoplay=1")
            params.append("mute=1")
        }
        
        // Essential parameters for iOS playback
        params.append("playsinline=1")      // Play inline on iOS
        params.append("controls=1")          // Show player controls
        params.append("rel=0")               // Don't show related videos
        params.append("modestbranding=1")    // Minimal YouTube branding
        
        // Append parameters to URL
        let separator = urlString.contains("?") ? "&" : "?"
        let paramString = params.joined(separator: "&")
        urlString += separator + paramString
        
        // Load directly via URLRequest (more reliable than HTML wrapper)
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

/// A thumbnail view for YouTube videos (shows a play button overlay)
struct YouTubeThumbnailView: View {
    let embedURL: String
    let width: CGFloat
    let height: CGFloat
    
    @State private var thumbnailURL: URL?
    
    var body: some View {
        ZStack {
            if let thumbnailURL = thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                    case .failure:
                        placeholderView
                    case .empty:
                        ProgressView()
                            .frame(width: width, height: height)
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
            
            // Enhanced play button overlay with Liquid Glass
            Button(action: {}) {
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .offset(x: 2) // Slight offset to visually center the play icon
            }
            .frame(width: 60, height: 60)
            .liquidGlass(
                tint: Color.white.opacity(0.15),
                in: Circle(),
                isInteractive: true
            )
            .disabled(true) // Disabled since this is just a thumbnail
        }
        .frame(width: width, height: height)
        .onAppear {
            extractThumbnailURL()
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Video")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .liquidGlass(
                tint: Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .padding()
        }
        .frame(width: width, height: height)
    }
    
    private func extractThumbnailURL() {
        // Extract video ID from embed URL
        if let videoID = extractVideoID(from: embedURL) {
            // YouTube thumbnail URL format
            thumbnailURL = URL(string: "https://img.youtube.com/vi/\(videoID)/mqdefault.jpg")
        }
    }
    
    private func extractVideoID(from urlString: String) -> String? {
        if let url = URL(string: urlString) {
            // From embed URL: youtube.com/embed/VIDEO_ID
            if url.path.contains("/embed/") {
                let components = url.path.components(separatedBy: "/")
                if let videoID = components.last, !videoID.isEmpty {
                    return videoID
                }
            }
        }
        return nil
    }
}
