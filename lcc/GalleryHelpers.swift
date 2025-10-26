import Foundation

/// Clamp an index into valid bounds for a collection of given count.
/// Returns 0 for empty collections.
func clampIndex(_ index: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(0, index), count - 1)
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
    case .youtubeVideo:
        // No image proxy for videos; hide share (nil)
        return nil
    }
}


