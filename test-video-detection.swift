import Foundation

// Test the MediaItem detection
let testURLs = [
    "https://youtube.com/embed/dQw4w9WgXcQ",
    "https://youtube.com/watch?v=dQw4w9WgXcQ",
    "https://youtu.be/dQw4w9WgXcQ",
    "<iframe src=\"https://youtube.com/embed/dQw4w9WgXcQ\"></iframe>",
    "https://lcc.live/image/abc123"
]

print("Testing MediaItem detection:")
for url in testURLs {
    if let item = MediaItem.from(urlString: url) {
        let typeStr = item.type.isVideo ? "VIDEO" : "IMAGE"
        print("✅ \(typeStr): \(url)")
    }
}
