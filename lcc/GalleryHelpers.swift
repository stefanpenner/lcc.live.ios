import Foundation

/// Clamp an index into valid bounds for a collection of given count.
/// Returns 0 for empty collections.
func clampIndex(_ index: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(0, index), count - 1)
}

/// Extract YouTube video ID from various URL formats
/// Supports: youtube.com/embed/*, youtube.com/watch?v=*, youtu.be/*
private func extractYouTubeVideoID(from urlString: String) -> String? {
    // Pattern 1: Embed URL (youtube.com/embed/VIDEO_ID)
    if urlString.contains("youtube.com/embed/") {
        if let url = URL(string: urlString) {
            let videoID = url.lastPathComponent.components(separatedBy: "?").first
            return videoID
        }
    }
    
    // Pattern 2: Watch URL (youtube.com/watch?v=VIDEO_ID)
    if urlString.contains("youtube.com/watch") {
        if let url = URL(string: urlString),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoID
        }
    }
    
    // Pattern 3: Short URL (youtu.be/VIDEO_ID)
    if urlString.contains("youtu.be/") {
        if let url = URL(string: urlString) {
            return url.lastPathComponent.components(separatedBy: "?").first
        }
    }
    
    return nil
}

/// Resolve a shareable URL for a media item.
/// Returns nil if the item's URL string is invalid.
func galleryShareURL(for media: MediaItem?) -> URL? {
    guard let media = media else { return nil }
    switch media.type {
    case .image:
        // Pass through if already proxied via lcc.live
        if media.url.hasPrefix("https://lcc.live/image/") {
            return URL(string: media.url)
        }
        // Otherwise, wrap original in lcc.live/image/<base64>
        guard let data = media.url.data(using: .utf8) else { return nil }
        let b64 = data.base64EncodedString()
        return URL(string: "https://lcc.live/image/\(b64)")
    case .youtubeVideo(let embedURL):
        // Extract video ID and return standard YouTube watch URL
        if let videoID = extractYouTubeVideoID(from: embedURL) {
            return URL(string: "https://www.youtube.com/watch?v=\(videoID)")
        }
        // Fallback: return original URL if present
        return URL(string: media.url)
    }
}


