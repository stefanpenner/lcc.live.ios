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
    private let logger = Logger(category: .networking)
    
    private var baseURL: String {
        AppEnvironment.apiBaseURL
    }
    
    private var checkInterval: TimeInterval {
        AppEnvironment.apiCheckInterval
    }
    
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
                    logger.info("Server version changed from \(previousVersion) to \(currentVersion). Refreshing data...")
                    await fetchAllImages()
                }
            }
        } catch {
            logger.error("Error checking server version", error: error)
        }
    }
    
    /// Fetch the server version from headers
    private func fetchServerVersion() async throws -> String {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "HEAD"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = AppEnvironment.networkTimeout
        
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
            logger.error("Invalid URL: \(urlString)")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = AppEnvironment.networkTimeout
        
        // Track API request
        let startTime = Date()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Track successful API call
            let duration = Date().timeIntervalSince(startTime)
            MetricsService.shared.track(
                event: .apiSuccess,
                duration: duration,
                tags: ["endpoint": updateType == .lcc ? "lcc" : "bcc"]
            )
            
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
                    self.logger.info("✅ Fetched \(mediaItems.count) LCC media items from API")
                case .bcc:
                    self.bccMedia = mediaItems
                    self.logger.info("✅ Fetched \(mediaItems.count) BCC media items from API")
                }
            }
        } catch {
            // Track API failure
            let duration = Date().timeIntervalSince(startTime)
            MetricsService.shared.track(
                event: .apiFailure,
                duration: duration,
                tags: [
                    "endpoint": updateType == .lcc ? "lcc" : "bcc",
                    "error": error.localizedDescription
                ]
            )
            
            logger.error("⚠️ Error fetching media from \(urlString)", error: error)
            if self.isUsingFallback {
                logger.info("ℹ️ Using fallback data")
            }
            
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
        
        // Try parsing as objects with identifiers first
        if let mediaItems = extractMediaItemsWithIdentifiers(from: json), !mediaItems.isEmpty {
            logger.debug("📊 Parsed \(mediaItems.count) media items with identifiers from API")
            return mediaItems
        }
        
        // Fallback to URL strings format
        if let urlStrings = extractURLStrings(from: json), !urlStrings.isEmpty {
            logger.debug("📊 Parsed \(urlStrings.count) URL strings from API")
            return urlStrings.compactMap { MediaItem.from(urlString: $0) }
        }
        
        throw APIError.invalidJSONFormat
    }
    
    /// Extract URL strings from various JSON formats
    private func extractURLStrings(from json: Any) -> [String]? {
        // Format 1: Array of strings
        if let stringArray = json as? [String] {
            return stringArray
        }
        
        // Format 2: Array of objects
        if let objectArray = json as? [[String: Any]] {
            return extractURLs(fromObjectArray: objectArray)
        }
        
        // Format 3: Object with cameras or images array
        if let object = json as? [String: Any] {
            return extractURLs(fromObject: object)
        }
        
        return nil
    }
    
    /// Extract media items with identifiers from JSON
    private func extractMediaItemsWithIdentifiers(from json: Any) -> [MediaItem]? {
        // Format 1: Array of objects with identifiers
        if let objectArray = json as? [[String: Any]] {
            return objectArray.compactMap { extractMediaItem(from: $0) }
        }
        
        // Format 2: Object with cameras array
        if let object = json as? [String: Any],
           let cameras = object["cameras"] as? [[String: Any]] {
            return cameras.compactMap { extractMediaItem(from: $0) }
        }
        
        // Format 3: Object with images array of objects
        if let object = json as? [String: Any],
           let images = object["images"] as? [[String: Any]] {
            return images.compactMap { extractMediaItem(from: $0) }
        }
        
        return nil
    }
    
    /// Extract a MediaItem from a single object, including identifier if available
    private func extractMediaItem(from object: [String: Any]) -> MediaItem? {
        // Extract URL
        guard let urlString = extractURL(from: object) else { return nil }
        
        // Extract identifier (check common field names)
        let identifier: String? = {
            if let id = object["id"] as? String { return id }
            if let id = object["identifier"] as? String { return id }
            if let id = object["idf"] as? String { return id }
            if let id = object["id"] as? Int { return String(id) }
            if let id = object["identifier"] as? Int { return String(id) }
            if let id = object["idf"] as? Int { return String(id) }
            return nil
        }()
        
        return MediaItem.from(urlString: urlString, identifier: identifier)
    }
    
    /// Extract URLs from an array of objects
    private func extractURLs(fromObjectArray objects: [[String: Any]]) -> [String] {
        return objects.compactMap { extractURL(from: $0) }
    }
    
    /// Extract URLs from an object with cameras or images array
    private func extractURLs(fromObject object: [String: Any]) -> [String]? {
        // Check for cameras array (new API format)
        if let cameras = object["cameras"] as? [[String: Any]] {
            return cameras.compactMap { extractURL(from: $0) }
        }
        
        // Check for images array (legacy format)
        if let images = object["images"] as? [String] {
            return images
        }
        
        if let images = object["images"] as? [[String: Any]] {
            return images.compactMap { extractURL(from: $0) }
        }
        
        return nil
    }
    
    /// Extract URL string from a single object
    private func extractURL(from object: [String: Any]) -> String? {
        // Check common URL field names in order of preference
        if let iframe = object["iframe"] as? String { return iframe }
        if let url = object["url"] as? String { return url }
        if let src = object["src"] as? String { return src }
        return nil
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

