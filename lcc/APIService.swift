import Foundation
import Combine

class APIService: ObservableObject {
    @Published var lccMedia: [MediaItem] = []
    @Published var bccMedia: [MediaItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isUsingFallback = false
    
    private var serverVersion: String?
    private var timer: Timer?
    private let checkInterval: TimeInterval = 30.0 // Check every 30 seconds
    private let baseURL = "https://lcc.live"
    
    init() {
        // Start with empty arrays, fetch from API immediately
        self.lccMedia = []
        self.bccMedia = []
        self.isUsingFallback = false
        
        // Fetch from API
        startVersionMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    /// Start monitoring for server version changes
    private func startVersionMonitoring() {
        // Fetch immediately on init
        Task {
            await fetchAllImages()
        }
        
        // Set up timer to check periodically
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.checkServerVersionAndRefresh()
            }
        }
    }
    
    /// Check if server version has changed and refresh if needed
    private func checkServerVersionAndRefresh() async {
        do {
            let currentVersion = try await fetchServerVersion()
            
            if let previousVersion = serverVersion {
                if currentVersion != previousVersion {
                    #if DEBUG
                    NSLog("[APIService] Server version changed from \(previousVersion) to \(currentVersion). Refreshing data...")
                    #endif
                    await fetchAllImages()
                }
            }
        } catch {
            #if DEBUG
            NSLog("[APIService] Error checking server version: \(error.localizedDescription)")
            #endif
        }
    }
    
    /// Fetch the server version from headers
    private func fetchServerVersion() async throws -> String {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "HEAD"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Check common version headers
        if let version = httpResponse.value(forHTTPHeaderField: "X-Server-Version") ??
                         httpResponse.value(forHTTPHeaderField: "X-Version") ??
                         httpResponse.value(forHTTPHeaderField: "ETag") {
            return version
        }
        
        // Fallback to Last-Modified
        if let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
            return lastModified
        }
        
        // If no version header, use a timestamp-based approach
        return String(Date().timeIntervalSince1970)
    }
    
    /// Fetch all media from both endpoints
    func fetchAllImages() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchLCCMedia()
            }
            group.addTask {
                await self.fetchBCCMedia()
            }
        }
    }
    
    /// Fetch LCC media from the default endpoint
    func fetchLCCMedia() async {
        await fetchMedia(from: "\(baseURL)/lcc.json", updateType: .lcc)
    }
    
    /// Fetch BCC media from the /bcc endpoint
    func fetchBCCMedia() async {
        await fetchMedia(from: "\(baseURL)/bcc.json", updateType: .bcc)
    }
    
    private enum UpdateType {
        case lcc
        case bcc
    }
    
    /// Generic method to fetch media from an endpoint
    private func fetchMedia(from urlString: String, updateType: UpdateType) async {
        guard let url = URL(string: urlString) else {
            #if DEBUG
            NSLog("[APIService] Invalid URL: \(urlString)")
            #endif
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // Update server version from response headers
            if updateType == .lcc {
                if let version = httpResponse.value(forHTTPHeaderField: "X-Server-Version") ??
                                 httpResponse.value(forHTTPHeaderField: "X-Version") ??
                                 httpResponse.value(forHTTPHeaderField: "ETag") ??
                                 httpResponse.value(forHTTPHeaderField: "Last-Modified") {
                    await MainActor.run {
                        self.serverVersion = version
                    }
                }
            }
            
            // Parse JSON - expecting array of strings or objects
            let mediaItems = try parseMediaItems(from: data)
            
            await MainActor.run {
                // Mark that we successfully fetched from API
                self.isUsingFallback = false
                
                switch updateType {
                case .lcc:
                    self.lccMedia = mediaItems
                    #if DEBUG
                    NSLog("[APIService] ✅ Fetched \(mediaItems.count) LCC media items from API")
                    #endif
                case .bcc:
                    self.bccMedia = mediaItems
                    #if DEBUG
                    NSLog("[APIService] ✅ Fetched \(mediaItems.count) BCC media items from API")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            NSLog("[APIService] ⚠️ Error fetching media from \(urlString): \(error.localizedDescription)")
            if self.isUsingFallback {
                NSLog("[APIService] ℹ️ Using fallback data")
            }
            #endif
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    /// Parse media items from JSON data
    /// Supports multiple formats:
    /// - Array of strings: ["url1", "url2", ...]
    /// - Array of objects: [{"url": "url1"}, {"url": "url2"}, {"iframe": "<iframe...>"}, ...]
    /// - Object with images array: {"images": ["url1", "url2", ...]}
    /// - Object with cameras array: {"cameras": [{"kind": "img", "src": "url"}, {"kind": "iframe", "src": "..."}]}
    private func parseMediaItems(from data: Data) throws -> [MediaItem] {
        let json = try JSONSerialization.jsonObject(with: data)
        var urlStrings: [String] = []
        
        // Try array of strings
        if let stringArray = json as? [String] {
            urlStrings = stringArray
        }
        // Try array of objects with "url" or "iframe" field
        else if let objectArray = json as? [[String: Any]] {
            urlStrings = objectArray.compactMap { object in
                // Check for iframe field (YouTube embed)
                if let iframe = object["iframe"] as? String {
                    return iframe
                }
                // Check for url field
                if let url = object["url"] as? String {
                    return url
                }
                // Check for src field (cameras array format)
                if let src = object["src"] as? String {
                    return src
                }
                return nil
            }
        }
        // Try object with "cameras" or "images" array
        else if let object = json as? [String: Any] {
            // Check for cameras array (new API format)
            if let cameras = object["cameras"] as? [[String: Any]] {
                urlStrings = cameras.compactMap { camera in
                    // Get the src field which contains the URL or iframe
                    if let src = camera["src"] as? String {
                        return src
                    }
                    // Also check iframe field as fallback
                    if let iframe = camera["iframe"] as? String {
                        return iframe
                    }
                    return nil
                }
            }
            // Check for images array (legacy format)
            else if let images = object["images"] as? [String] {
                urlStrings = images
            } else if let images = object["images"] as? [[String: Any]] {
                urlStrings = images.compactMap { obj in
                    if let iframe = obj["iframe"] as? String {
                        return iframe
                    }
                    if let url = obj["url"] as? String {
                        return url
                    }
                    if let src = obj["src"] as? String {
                        return src
                    }
                    return nil
                }
            }
        }
        
        if urlStrings.isEmpty {
            throw APIError.invalidJSONFormat
        }
        
        #if DEBUG
        NSLog("[APIService] 📊 Parsed \(urlStrings.count) URL strings from API")
        #endif
        
        // Convert URL strings to MediaItems
        return urlStrings.compactMap { MediaItem.from(urlString: $0) }
    }
    
    /// Manually trigger a refresh
    func refresh() async {
        await fetchAllImages()
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidJSONFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .invalidJSONFormat:
            return "Invalid JSON format"
        }
    }
}

