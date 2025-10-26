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
        configuration.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : .all
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Build the embed URL with parameters
        var urlString = embedURL
        
        // Add autoplay parameter if needed
        if autoplay {
            urlString += embedURL.contains("?") ? "&autoplay=1&mute=1" : "?autoplay=1&mute=1"
        }
        
        // Add other useful parameters
        let params = [
            "playsinline=1",           // Play inline on iOS
            "rel=0",                    // Don't show related videos
            "modestbranding=1",         // Minimal YouTube branding
            "controls=1",               // Show player controls
            "showinfo=0",               // Hide video info
            "enablejsapi=1"             // Enable JavaScript API
        ]
        
        for param in params {
            urlString += urlString.contains("?") ? "&\(param)" : "?\(param)"
        }
        
        // Wrap in proper HTML with responsive iframe
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    border: 0;
                }
                html, body {
                    width: 100%;
                    height: 100%;
                    background-color: #000;
                    overflow: hidden;
                }
                .video-container {
                    position: relative;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe src="\(urlString)" 
                        frameborder="0" 
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
                        allowfullscreen>
                </iframe>
            </div>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
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
