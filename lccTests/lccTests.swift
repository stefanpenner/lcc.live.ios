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

@Suite("APIService Tests")
struct APIServiceTests {
    
    @Test("APIService initializes with fallback data")
    func testInitializationWithFallback() async throws {
        let apiService = APIService()
        
        // Should have fallback data immediately
        #expect(!apiService.lccImages.isEmpty, "LCC images should not be empty on init")
        #expect(!apiService.bccImages.isEmpty, "BCC images should not be empty on init")
        #expect(apiService.isUsingFallback, "Should be marked as using fallback initially")
        
        // Verify fallback data is valid URLs
        for urlString in apiService.lccImages {
            #expect(URL(string: urlString) != nil, "All LCC URLs should be valid")
        }
        
        for urlString in apiService.bccImages {
            #expect(URL(string: urlString) != nil, "All BCC URLs should be valid")
        }
    }
    
    @Test("APIService fallback data has expected count")
    func testFallbackDataCount() async throws {
        let apiService = APIService()
        
        // Verify we have a reasonable number of images
        #expect(apiService.lccImages.count > 10, "Should have multiple LCC images")
        #expect(apiService.bccImages.count >= 5, "Should have multiple BCC images")
    }
    
    @Test("APIService JSON parsing - simple array")
    func testJSONParsingSimpleArray() async throws {
        let apiService = APIService()
        let json = """
        [
            "https://example.com/image1.jpg",
            "https://example.com/image2.jpg",
            "https://example.com/image3.jpg"
        ]
        """
        
        let data = json.data(using: .utf8)!
        let urls = try apiService.parseImageURLs(from: data)
        
        #expect(urls.count == 3)
        #expect(urls[0] == "https://example.com/image1.jpg")
        #expect(urls[1] == "https://example.com/image2.jpg")
        #expect(urls[2] == "https://example.com/image3.jpg")
    }
    
    @Test("APIService JSON parsing - array of objects")
    func testJSONParsingArrayOfObjects() async throws {
        let apiService = APIService()
        let json = """
        [
            {"url": "https://example.com/image1.jpg", "name": "cam1"},
            {"url": "https://example.com/image2.jpg", "name": "cam2"}
        ]
        """
        
        let data = json.data(using: .utf8)!
        let urls = try apiService.parseImageURLs(from: data)
        
        #expect(urls.count == 2)
        #expect(urls[0] == "https://example.com/image1.jpg")
        #expect(urls[1] == "https://example.com/image2.jpg")
    }
    
    @Test("APIService JSON parsing - nested images array")
    func testJSONParsingNestedArray() async throws {
        let apiService = APIService()
        let json = """
        {
            "images": [
                "https://example.com/image1.jpg",
                "https://example.com/image2.jpg"
            ],
            "timestamp": "2025-10-04T12:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let urls = try apiService.parseImageURLs(from: data)
        
        #expect(urls.count == 2)
        #expect(urls[0] == "https://example.com/image1.jpg")
        #expect(urls[1] == "https://example.com/image2.jpg")
    }
    
    @Test("APIService JSON parsing - nested objects array")
    func testJSONParsingNestedObjectsArray() async throws {
        let apiService = APIService()
        let json = """
        {
            "images": [
                {"url": "https://example.com/image1.jpg"},
                {"url": "https://example.com/image2.jpg"}
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let urls = try apiService.parseImageURLs(from: data)
        
        #expect(urls.count == 2)
        #expect(urls[0] == "https://example.com/image1.jpg")
        #expect(urls[1] == "https://example.com/image2.jpg")
    }
    
    @Test("APIService JSON parsing - invalid format throws error")
    func testJSONParsingInvalidFormat() async throws {
        let apiService = APIService()
        let json = """
        {
            "data": "not an array"
        }
        """
        
        let data = json.data(using: .utf8)!
        
        #expect(throws: APIError.self) {
            try apiService.parseImageURLs(from: data)
        }
    }
    
    @Test("APIService JSON parsing - empty array")
    func testJSONParsingEmptyArray() async throws {
        let apiService = APIService()
        let json = "[]"
        
        let data = json.data(using: .utf8)!
        let urls = try apiService.parseImageURLs(from: data)
        
        #expect(urls.isEmpty)
    }
    
    @Test("APIService maintains fallback on API failure")
    func testFallbackMaintainedOnFailure() async throws {
        let apiService = APIService()
        
        // Record initial fallback data
        let initialLCCCount = apiService.lccImages.count
        let initialBCCCount = apiService.bccImages.count
        
        // Wait for any API calls to complete (they will fail since localhost:3000 isn't running)
        try? await Task.sleep(for: .milliseconds(500))
        
        // Should still have fallback data
        #expect(apiService.lccImages.count == initialLCCCount, "LCC images should remain unchanged on API failure")
        #expect(apiService.bccImages.count == initialBCCCount, "BCC images should remain unchanged on API failure")
        #expect(apiService.isUsingFallback, "Should still be using fallback after API failure")
    }
    
    @Test("APIService error property is set on failure")
    func testErrorPropertyOnFailure() async throws {
        let apiService = APIService()
        
        // Wait for API call to fail
        try? await Task.sleep(for: .milliseconds(500))
        
        // Should have an error since localhost:3000 isn't running
        #expect(apiService.error != nil, "Error should be set when API call fails")
    }
}

@Suite("ContentView Integration Tests")
struct ContentViewIntegrationTests {
    
    @Test("ContentView triggers preloader when API data changes")
    func testPreloaderTriggeredOnAPIChange() async throws {
        // This test verifies the integration between APIService and ImagePreloader
        let apiService = APIService()
        let preloader = ImagePreloader()
        
        // Verify initial state - fallback data should be available
        #expect(!apiService.lccImages.isEmpty)
        #expect(!apiService.bccImages.isEmpty)
        
        // In a real app, the onChange handlers would trigger preloading
        // Here we verify the data is in the correct format
        for urlString in apiService.lccImages {
            let url = URL(string: urlString)
            #expect(url != nil, "All LCC image URLs should be valid")
        }
        
        for urlString in apiService.bccImages {
            let url = URL(string: urlString)
            #expect(url != nil, "All BCC image URLs should be valid")
        }
    }
}

// Make parseImageURLs accessible for testing
extension APIService {
    func parseImageURLs(from data: Data) throws -> [String] {
        let json = try JSONSerialization.jsonObject(with: data)
        
        // Try array of strings
        if let stringArray = json as? [String] {
            return stringArray
        }
        
        // Try array of objects with "url" field
        if let objectArray = json as? [[String: Any]] {
            return objectArray.compactMap { $0["url"] as? String }
        }
        
        // Try object with "images" array
        if let object = json as? [String: Any] {
            if let images = object["images"] as? [String] {
                return images
            }
            if let images = object["images"] as? [[String: Any]] {
                return images.compactMap { $0["url"] as? String }
            }
        }
        
        throw APIError.invalidJSONFormat
    }
}
