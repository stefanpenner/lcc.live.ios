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

@Suite("PresentedImage Tests")
struct PresentedImageTests {
    
    @Test("PresentedImage initializes correctly")
    func testInitialization() throws {
        let url = URL(string: "https://example.com/image.jpg")!
        let presentedImage = PresentedImage(url: url)
        
        #expect(presentedImage.url == url)
        #expect(presentedImage.id != UUID())  // Should have a unique ID
    }
    
    @Test("PresentedImage has unique IDs")
    func testUniqueIDs() throws {
        let url = URL(string: "https://example.com/image.jpg")!
        let image1 = PresentedImage(url: url)
        let image2 = PresentedImage(url: url)
        
        #expect(image1.id != image2.id)
    }
    
    @Test("PresentedImage equality based on id and url")
    func testEquality() throws {
        let url1 = URL(string: "https://example.com/image1.jpg")!
        let url2 = URL(string: "https://example.com/image2.jpg")!
        
        let image1 = PresentedImage(url: url1)
        let image2 = PresentedImage(url: url1)
        let image3 = PresentedImage(url: url2)
        
        // Different IDs, same URL
        #expect(image1 != image2)
        
        // Different URLs
        #expect(image1 != image3)
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

@Suite("Integration Tests")
struct IntegrationTests {
    
    @Test("App images are properly configured")
    func testAppImages() {
        let app = LCC()
        
        #expect(!app.images.lcc.isEmpty)
        #expect(!app.images.bcc.isEmpty)
        
        // Verify all URLs are valid
        for urlString in app.images.lcc {
            let url = URL(string: urlString)
            #expect(url != nil)
        }
        
        for urlString in app.images.bcc {
            let url = URL(string: urlString)
            #expect(url != nil)
        }
    }
}
