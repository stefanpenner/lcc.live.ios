import Foundation
import Combine

class APIService: ObservableObject {
    @Published var lccImages: [String] = []
    @Published var bccImages: [String] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isUsingFallback = false
    
    private var serverVersion: String?
    private var timer: Timer?
    private let checkInterval: TimeInterval = 30.0 // Check every 30 seconds
    private let baseURL = "https://lcc.live"
    
    // Fallback data when API is not available
    private let fallbackLCCImages = [
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0NvbGxpbnNfU25vd19TdGFrZS5qcGc=",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNjkuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyNzAuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjcuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjguanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTcyMjYuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL1N1cGVyaW9yLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0hpZ2hydXN0bGVyLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL3N1Z2FyX3BlYWsuanBn",
        "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL2NvbGxpbnNfZHRjLmpwZw==",
        "https://lcc.live/image/aHR0cHM6Ly9hcHAucHJpc21jYW0uY29tL3B1YmxpYy9oZWxwZXJzL3JlYWx0aW1lX3ByZXZpZXcucGhwP2M9ODgmcz03MjA=",
        "https://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80OGZjMjIzYzBlZDg4NDc0ZWNjMmY4ODRiZjM5ZGU2My9tZWRpdW0=",
        "https://lcc.live/image/aHR0cHM6Ly9iYWNrZW5kLnJvdW5kc2hvdC5jb20vY2Ftcy80NGNmZmY0ZmYyYTIxOGExMTc4ZGJiMTA1ZDk1ODQ2YS9tZWRpdW0=",
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzU3ODA3NTRmLThkYTEtNDIyMy1hYjhhLTY3NTVkODRjYmMxMC9zbmFwc2hvdA==",
        "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzYxYjI0OTBiZTEwMWMwMGI5YzQ4Mzc0Zi9zbmFwc2hvdA==",
    ]
    
    private let fallbackBCCImages = [
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTUuanBlZw==",
        "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTYuanBlZw==",
    ]
    
    init() {
        // Initialize with fallback data immediately
        self.lccImages = fallbackLCCImages
        self.bccImages = fallbackBCCImages
        self.isUsingFallback = true
        
        // Then try to fetch from API
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
    
    /// Fetch all images from both endpoints
    func fetchAllImages() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchLCCImages()
            }
            group.addTask {
                await self.fetchBCCImages()
            }
        }
    }
    
    /// Fetch LCC images from the default endpoint
    func fetchLCCImages() async {
        await fetchImages(from: baseURL, updateType: .lcc)
    }
    
    /// Fetch BCC images from the /bcc endpoint
    func fetchBCCImages() async {
        await fetchImages(from: "\(baseURL)/bcc", updateType: .bcc)
    }
    
    private enum UpdateType {
        case lcc
        case bcc
    }
    
    /// Generic method to fetch images from an endpoint
    private func fetchImages(from urlString: String, updateType: UpdateType) async {
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
            
            // Parse JSON - expecting array of strings or objects with url field
            let images = try parseImageURLs(from: data)
            
            await MainActor.run {
                // Mark that we successfully fetched from API
                self.isUsingFallback = false
                
                switch updateType {
                case .lcc:
                    self.lccImages = images
                    #if DEBUG
                    NSLog("[APIService] ✅ Fetched \(images.count) LCC images from API")
                    #endif
                case .bcc:
                    self.bccImages = images
                    #if DEBUG
                    NSLog("[APIService] ✅ Fetched \(images.count) BCC images from API")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            NSLog("[APIService] ⚠️ Error fetching images from \(urlString): \(error.localizedDescription)")
            if self.isUsingFallback {
                NSLog("[APIService] ℹ️ Using fallback data")
            }
            #endif
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    /// Parse image URLs from JSON data
    /// Supports multiple formats:
    /// - Array of strings: ["url1", "url2", ...]
    /// - Array of objects: [{"url": "url1"}, {"url": "url2"}, ...]
    /// - Object with images array: {"images": ["url1", "url2", ...]}
    private func parseImageURLs(from data: Data) throws -> [String] {
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

