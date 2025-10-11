import Foundation

/// Represents a media item that can be either an image or a video
struct MediaItem: Identifiable, Hashable {
    let id = UUID()
    let type: MediaType
    let url: String
    
    enum MediaType: Hashable {
        case image
        case youtubeVideo(embedURL: String)
        
        var isVideo: Bool {
            if case .youtubeVideo = self {
                return true
            }
            return false
        }
    }
    
    /// Parses a URL string to determine if it's an image or YouTube video
    static func from(urlString: String) -> MediaItem? {
        // Check if it's a YouTube URL
        if let videoURL = extractYouTubeEmbedURL(from: urlString) {
            Logger.ui.debug("✅ Detected YouTube video: \(urlString)")
            return MediaItem(type: .youtubeVideo(embedURL: videoURL), url: urlString)
        }
        
        // Default to image
        return MediaItem(type: .image, url: urlString)
    }
    
    /// Extracts YouTube embed URL from various YouTube URL formats
    /// Supports: youtube.com/embed/*, youtube.com/watch?v=*, youtu.be/*, iframe tags
    private static func extractYouTubeEmbedURL(from string: String) -> String? {
        // Pattern 1: Check for iframe with YouTube embed
        if string.contains("iframe") && string.contains("youtube.com/embed/") {
            if let range = string.range(of: "youtube\\.com/embed/[a-zA-Z0-9_-]+", options: .regularExpression) {
                let embedPath = String(string[range])
                return "https://www.\(embedPath)"
            }
        }
        
        // Pattern 2: Direct embed URL
        if string.contains("youtube.com/embed/") {
            if let url = URL(string: string), url.host?.contains("youtube.com") ?? false {
                return string
            }
        }
        
        // Pattern 3: Watch URL (youtube.com/watch?v=VIDEO_ID)
        if string.contains("youtube.com/watch") {
            if let url = URL(string: string),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return "https://www.youtube.com/embed/\(videoID)"
            }
        }
        
        // Pattern 4: Short URL (youtu.be/VIDEO_ID)
        if string.contains("youtu.be/") {
            if let url = URL(string: string), url.host == "youtu.be" {
                let videoID = url.lastPathComponent
                return "https://www.youtube.com/embed/\(videoID)"
            }
        }
        
        return nil
    }
    
    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}
