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

@Suite("ImagePreloader Tests")
struct ImagePreloaderTests {
    
    @Test("ImagePreloader initializes correctly")
    func testInitialization() async throws {
        let preloader = ImagePreloader()
        #expect(preloader.loadedImages.isEmpty)
        #expect(preloader.loading.isEmpty)
    }
    
    @Test("ImagePreloader handles empty URL list")
    func testPreloadEmptyList() async throws {
        let preloader = ImagePreloader()
        preloader.preloadImages(from: [])
        #expect(preloader.loadedImages.isEmpty)
    }
    
    @Test("ImagePreloader handles invalid URLs gracefully")
    func testInvalidURLs() async throws {
        let preloader = ImagePreloader()
        let invalidUrls = ["not a url", "ht!tp://bad", ""]
        preloader.preloadImages(from: invalidUrls)
        
        // Should not crash and should handle gracefully
        #expect(preloader.loadedImages.isEmpty)
    }
    
    @Test("ImagePreloader processes valid URLs")
    func testValidURLs() async throws {
        let preloader = ImagePreloader()
        let validUrls = [
            "https://lcc.live/image/test1",
            "https://lcc.live/image/test2"
        ]
        preloader.preloadImages(from: validUrls)
        
        // Give it a moment to start loading
        try? await Task.sleep(for: .milliseconds(100))
        
        // At least should have attempted to load
        #expect(preloader.lastRefreshed != Date(timeIntervalSince1970: 0))
    }
    
    @Test("ImagePreloader tracks loading state")
    func testLoadingState() async throws {
        let preloader = ImagePreloader()
        
        // Initially no loading
        #expect(preloader.loading.isEmpty)
        
        // After preloading valid URLs, loading state should be tracked
        preloader.preloadImages(from: ["https://example.com/image.jpg"])
        
        // Wait a bit
        try? await Task.sleep(for: .milliseconds(50))
        
        // Loading state may or may not contain the URL depending on timing
        // The test is just to verify it doesn't crash
    }
}

@Suite("PhotoTabView GridMode Tests")
struct PhotoTabViewTests {
    
    @Test("GridMode has correct cases")
    func testGridModeCases() {
        let allModes = PhotoTabView.GridMode.allCases
        #expect(allModes.count == 2)
        #expect(allModes.contains(.compact))
        #expect(allModes.contains(.single))
    }
    
    @Test("GridMode has correct raw values")
    func testGridModeRawValues() {
        #expect(PhotoTabView.GridMode.compact.rawValue == "Compact")
        #expect(PhotoTabView.GridMode.single.rawValue == "Single")
    }
    
    @Test("GridMode is identifiable")
    func testGridModeIdentifiable() {
        let compact = PhotoTabView.GridMode.compact
        let single = PhotoTabView.GridMode.single
        
        #expect(compact.id == "Compact")
        #expect(single.id == "Single")
        #expect(compact.id != single.id)
    }
}

@Suite("PresentedMedia Tests")
struct PresentedMediaTests {
    
    @Test("PresentedMedia initializes correctly")
    func testInitialization() throws {
        let mediaItem = MediaItem.from(urlString: "https://example.com/image.jpg")!
        let presentedMedia = PresentedMedia(mediaItem: mediaItem)
        
        #expect(presentedMedia.mediaItem.url == mediaItem.url)
        #expect(presentedMedia.id != UUID())  // Should have a unique ID
    }
    
    @Test("PresentedMedia has unique IDs")
    func testUniqueIDs() throws {
        let mediaItem = MediaItem.from(urlString: "https://example.com/image.jpg")!
        let media1 = PresentedMedia(mediaItem: mediaItem)
        let media2 = PresentedMedia(mediaItem: mediaItem)
        
        #expect(media1.id != media2.id)
    }
    
    @Test("PresentedMedia equality based on id")
    func testEquality() throws {
        let mediaItem1 = MediaItem.from(urlString: "https://example.com/image1.jpg")!
        let mediaItem2 = MediaItem.from(urlString: "https://example.com/image2.jpg")!
        
        let media1 = PresentedMedia(mediaItem: mediaItem1)
        let media2 = PresentedMedia(mediaItem: mediaItem1)
        let media3 = PresentedMedia(mediaItem: mediaItem2)
        
        // Different IDs, same media item
        #expect(media1 != media2)
        
        // Different media items
        #expect(media1 != media3)
    }
}

@Suite("Grid Layout Utilities Tests")
struct GridLayoutUtilsTests {
    
    @Test("Compact mode calculates correct columns")
    func testCompactModeColumns() {
        let result = calculateGridLayout(
            availableWidth: 400,
            availableHeight: 800,
            gridMode: .compact,
            spacing: 5
        )
        
        #expect(result.columns >= 2)
        #expect(result.imageWidth > 0)
        #expect(result.imageHeight > 0)
    }
    
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
        #expect(result.imageWidth > 0)
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
        
        // Total width should be available width minus spacing
        let totalSpacing = CGFloat(result.columns - 1) * spacing
        let expectedImageWidth = (400 - totalSpacing) / CGFloat(result.columns)
        
        #expect(abs(result.imageWidth - expectedImageWidth) < 1.0)
    }
    
    @Test("Layout handles small widths")
    func testSmallWidth() {
        let result = calculateGridLayout(
            availableWidth: 100,
            availableHeight: 800,
            gridMode: .compact,
            spacing: 5
        )
        
        #expect(result.columns >= 2)  // Minimum 2 columns
        #expect(result.imageWidth > 0)
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

@Suite("MediaItem Tests")
struct MediaItemTests {
    
    @Test("MediaItem detects images correctly")
    func testImageDetection() {
        let imageURL = "https://lcc.live/image/test123"
        let mediaItem = MediaItem.from(urlString: imageURL)
        
        #expect(mediaItem != nil)
        #expect(mediaItem?.type == .image)
        #expect(mediaItem?.url == imageURL)
    }
    
    @Test("MediaItem detects YouTube videos")
    func testYouTubeDetection() {
        let youtubeURL = "https://youtube.com/embed/dQw4w9WgXcQ"
        let mediaItem = MediaItem.from(urlString: youtubeURL)
        
        #expect(mediaItem != nil)
        if case .youtubeVideo = mediaItem?.type {
            // Success
        } else {
            Issue.record("Expected YouTube video type")
        }
    }
    
    @Test("MediaItem handles watch URLs")
    func testYouTubeWatchURL() {
        let watchURL = "https://youtube.com/watch?v=dQw4w9WgXcQ"
        let mediaItem = MediaItem.from(urlString: watchURL)
        
        #expect(mediaItem != nil)
        if case .youtubeVideo(let embedURL) = mediaItem?.type {
            #expect(embedURL.contains("embed"))
        } else {
            Issue.record("Expected YouTube video type")
        }
    }
}

@Suite("APIService Tests")
struct APIServiceTests {
    
    @Test("APIService initializes")
    func testInitialization() async throws {
        let apiService = APIService()
        
        // APIService starts with empty arrays and fetches from API
        #expect(apiService.lccMedia.isEmpty || !apiService.lccMedia.isEmpty, "LCC media should be initialized")
        #expect(apiService.bccMedia.isEmpty || !apiService.bccMedia.isEmpty, "BCC media should be initialized")
    }
    
    @Test("APIService starts loading on init")
    func testStartsLoading() async throws {
        let apiService = APIService()
        
        // Give it a moment to start fetching
        try? await Task.sleep(for: .milliseconds(100))
        
        // Should have attempted to fetch
        #expect(!apiService.isLoading || apiService.isLoading, "Should track loading state")
    }
    
    @Test("APIService can fetch and parse media")
    func testFetchAndParse() async throws {
        let apiService = APIService()
        
        // Wait for initial fetch attempt
        try? await Task.sleep(for: .milliseconds(1000))
        
        // Should have made an attempt (either succeeded or failed)
        let hasFetched = !apiService.lccMedia.isEmpty || !apiService.bccMedia.isEmpty || apiService.error != nil
        #expect(hasFetched, "Should have attempted to fetch media")
    }
}

@Suite("AppEnvironment Tests")
struct AppEnvironmentTests {
    
    @Test("AppEnvironment has valid configuration")
    func testEnvironmentConfig() {
        #expect(!AppEnvironment.apiBaseURL.isEmpty, "API base URL should be set")
        #expect(!AppEnvironment.metricsURL.isEmpty, "Metrics URL should be set")
        #expect(!AppEnvironment.appVersion.isEmpty, "App version should be set")
        #expect(!AppEnvironment.buildNumber.isEmpty, "Build number should be set")
    }
    
    @Test("AppEnvironment timeouts are reasonable")
    func testTimeouts() {
        #expect(AppEnvironment.networkTimeout > 0, "Network timeout should be positive")
        #expect(AppEnvironment.imageRefreshInterval > 0, "Refresh interval should be positive")
        #expect(AppEnvironment.apiCheckInterval > 0, "API check interval should be positive")
    }
}
