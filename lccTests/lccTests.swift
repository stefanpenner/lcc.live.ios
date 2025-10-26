//
//  lccTests.swift
//  lccTests
//
//  Created by Stefan Penner on 4/30/25.
//

@testable import lcc
import Testing
import Foundation
import UIKit

// MARK: - Grid Layout Tests (Critical business logic)

@Suite("Grid Layout Tests")
struct GridLayoutUtilsTests {
    
    @Test("Single mode portrait calculates one column")
    func testSingleModePortrait() {
        let result = calculateGridLayout(
            availableWidth: 400,
            availableHeight: 800,
            gridMode: .single,
            spacing: 5
        )
        
        #expect(result.columns == 1)
        #expect(result.imageWidth <= 430)  // Max width
    }
    
    @Test("Single mode landscape calculates two columns")
    func testSingleModeLandscape() {
        let result = calculateGridLayout(
            availableWidth: 800,
            availableHeight: 400,
            gridMode: .single,
            spacing: 5
        )
        
        #expect(result.columns == 2)
    }
    
    @Test("Layout respects spacing")
    func testLayoutSpacing() {
        let spacing: CGFloat = 10
        let result = calculateGridLayout(
            availableWidth: 400,
            availableHeight: 800,
            gridMode: .compact,
            spacing: spacing
        )
        
        let totalSpacing = CGFloat(result.columns - 1) * spacing
        let expectedImageWidth = (400 - totalSpacing) / CGFloat(result.columns)
        
        #expect(abs(result.imageWidth - expectedImageWidth) < 1.0)
    }
    
    @Test("Layout maintains aspect ratio")
    func testAspectRatio() {
        let result = calculateGridLayout(
            availableWidth: 400,
            availableHeight: 800,
            gridMode: .compact,
            spacing: 5
        )
        
        let aspectRatio = result.imageHeight / result.imageWidth
        #expect(aspectRatio == 0.7)
    }
}

// MARK: - YouTube URL Parsing Tests (Critical for video support)

@Suite("YouTube URL Parsing Tests")
struct YouTubeVideoTests {
    
    @Test("Converts watch URLs to embed URLs")
    func testYouTubeWatchURLConversion() {
        let watchURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let mediaItem = MediaItem.from(urlString: watchURL)
        
        #expect(mediaItem != nil)
        if case .youtubeVideo(let embedURL) = mediaItem?.type {
            #expect(embedURL.contains("embed/dQw4w9WgXcQ"))
        } else {
            Issue.record("Expected YouTube video type with embed URL")
        }
    }
    
    @Test("Converts short URLs to embed URLs")
    func testYouTubeShortURL() {
        let shortURL = "https://youtu.be/dQw4w9WgXcQ"
        let mediaItem = MediaItem.from(urlString: shortURL)
        
        #expect(mediaItem != nil)
        if case .youtubeVideo(let embedURL) = mediaItem?.type {
            #expect(embedURL.contains("embed/dQw4w9WgXcQ"))
        } else {
            Issue.record("Expected YouTube video type with embed URL")
        }
    }
    
    @Test("Detects YouTube iframe tags")
    func testYouTubeIframe() {
        let iframeHTML = "<iframe src=\"https://www.youtube.com/embed/dQw4w9WgXcQ\" frameborder=\"0\"></iframe>"
        let mediaItem = MediaItem.from(urlString: iframeHTML)
        
        #expect(mediaItem != nil)
        if case .youtubeVideo(let embedURL) = mediaItem?.type {
            #expect(embedURL.contains("youtube.com/embed/dQw4w9WgXcQ"))
        } else {
            Issue.record("Expected YouTube video type from iframe")
        }
    }
    
    @Test("isVideo property distinguishes videos from images")
    func testIsVideoProperty() {
        let videoURL = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        let imageURL = "https://lcc.live/image/test123"
        
        let videoItem = MediaItem.from(urlString: videoURL)
        let imageItem = MediaItem.from(urlString: imageURL)
        
        #expect(videoItem?.type.isVideo == true)
        #expect(imageItem?.type.isVideo == false)
    }
}

// MARK: - Gallery Helper Tests (Critical for share functionality)

@Suite("Gallery Helper Tests")
struct GalleryHelperTests {
    
    @Test("clampIndex handles edge cases")
    func testClampIndexEdgeCases() {
        #expect(clampIndex(5, count: 0) == 0)      // Empty collection
        #expect(clampIndex(-5, count: 10) == 0)    // Negative index
        #expect(clampIndex(15, count: 10) == 9)    // Out of bounds
        #expect(clampIndex(5, count: 10) == 5)     // Valid index
    }
    
    @Test("galleryShareURL wraps image URLs in lcc.live proxy")
    func testShareURLImageProxy() {
        let imageURL = "https://example.com/image.jpg"
        let mediaItem = MediaItem.from(urlString: imageURL)
        
        let shareURL = galleryShareURL(for: mediaItem)
        #expect(shareURL?.absoluteString.hasPrefix("https://lcc.live/image/") == true)
    }
    
    @Test("galleryShareURL passes through already proxied images")
    func testShareURLAlreadyProxied() {
        let proxiedURL = "https://lcc.live/image/aGVsbG8="
        let mediaItem = MediaItem.from(urlString: proxiedURL)
        
        let shareURL = galleryShareURL(for: mediaItem)
        #expect(shareURL?.absoluteString == proxiedURL)
    }
    
    @Test("galleryShareURL generates YouTube watch URLs from embed URLs")
    func testShareURLYouTubeEmbed() {
        let embedURL = "https://www.youtube.com/embed/dQw4w9WgXcQ"
        let mediaItem = MediaItem.from(urlString: embedURL)
        
        let shareURL = galleryShareURL(for: mediaItem)
        #expect(shareURL?.absoluteString == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    }
    
    @Test("galleryShareURL handles YouTube short URLs")
    func testShareURLYouTubeShort() {
        let shortURL = "https://youtu.be/dQw4w9WgXcQ"
        let mediaItem = MediaItem.from(urlString: shortURL)
        
        let shareURL = galleryShareURL(for: mediaItem)
        #expect(shareURL?.absoluteString == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    }
    
    @Test("galleryShareURL handles YouTube URLs with parameters")
    func testShareURLYouTubeWithParams() {
        let embedURLWithParams = "https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1"
        let mediaItem = MediaItem.from(urlString: embedURLWithParams)
        
        let shareURL = galleryShareURL(for: mediaItem)
        #expect(shareURL?.absoluteString == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    }
    
    @Test("galleryShareURL base64 encodes original image URLs correctly")
    func testShareURLBase64Encoding() {
        let originalURL = "https://example.com/image.jpg"
        let mediaItem = MediaItem.from(urlString: originalURL)
        
        let shareURL = galleryShareURL(for: mediaItem)
        #expect(shareURL != nil)
        
        // Verify base64 encoding is reversible
        if let urlString = shareURL?.absoluteString,
           urlString.hasPrefix("https://lcc.live/image/") {
            let base64Part = urlString.replacingOccurrences(of: "https://lcc.live/image/", with: "")
            if let data = Data(base64Encoded: base64Part),
               let decoded = String(data: data, encoding: .utf8) {
                #expect(decoded == originalURL)
            } else {
                Issue.record("Failed to decode base64")
            }
        } else {
            Issue.record("Expected lcc.live proxy URL")
        }
    }
}

// MARK: - Invalid Input Tests (Edge cases)

@Suite("Invalid Input Handling Tests")
struct InvalidInputTests {
    
    @Test("ImagePreloader handles invalid URLs gracefully")
    func testInvalidURLs() async throws {
        let preloader = ImagePreloader()
        let invalidUrls = ["not a url", "ht!tp://bad", ""]
        preloader.preloadImages(from: invalidUrls)
        
        // Should not crash
        #expect(preloader.loadedImages.isEmpty)
    }
    
    @Test("galleryShareURL returns nil for nil media")
    func testShareURLNilMedia() {
        let result = galleryShareURL(for: nil)
        #expect(result == nil)
    }
}
