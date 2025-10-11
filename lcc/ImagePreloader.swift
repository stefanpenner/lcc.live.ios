import Foundation
import UIKit

class ImagePreloader: ObservableObject {
    @Published var loadedImages: [URL: UIImage] = [:]
    @Published var lastRefreshed: Date = .init()
    @Published var loading: Set<URL> = []
    @Published var fadingOut: [URL: Date] = [:]
    private var urls: [URL] = []
    private var timer: Timer?
    private var etags: [URL: String] = [:]
    private var lastModifieds: [URL: String] = [:]
    private var hasLoadedOnce: Set<URL> = []
    private let logger = Logger(category: .imageLoading)
    
    private var refreshInterval: TimeInterval {
        AppEnvironment.imageRefreshInterval
    }
    
    // Memory management
    private let maxCachedImages = 100
    private var cacheAccessTimes: [URL: Date] = [:]
    
    // Efficient refresh queue
    private var refreshQueue: [URL] = []
    private let maxConcurrentLoads = 3
    private let batchRefreshInterval: TimeInterval = 0.5 // Process queue every 500ms

    init() {
        startBackgroundRefresh()
        setupMemoryWarningHandler()
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryWarningHandler() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        logger.warning("Memory warning received - clearing image cache")
        
        // Keep only the most recently accessed images
        let sortedByAccess = cacheAccessTimes.sorted { $0.value > $1.value }
        let urlsToKeep = Set(sortedByAccess.prefix(20).map { $0.key })
        
        loadedImages = loadedImages.filter { urlsToKeep.contains($0.key) }
        cacheAccessTimes = cacheAccessTimes.filter { urlsToKeep.contains($0.key) }
        
        logger.info("Cleared cache, kept \(loadedImages.count) images")
        
        // Track memory warning
        MetricsService.shared.track(event: .memoryWarning, tags: ["source": "image_cache"])
    }
    
    private func pruneCache() {
        guard loadedImages.count > maxCachedImages else { return }
        
        // Do pruning off main thread to avoid blocking
        let imagesToRemove = loadedImages.count - maxCachedImages
        let sortedByAccess = cacheAccessTimes.sorted { $0.value < $1.value }
        let urlsToRemove = sortedByAccess.prefix(imagesToRemove).map { $0.key }
        
        DispatchQueue.main.async {
            for url in urlsToRemove {
                self.loadedImages.removeValue(forKey: url)
                self.cacheAccessTimes.removeValue(forKey: url)
            }
            
            self.logger.debug("Pruned cache: removed \(urlsToRemove.count) images")
        }
    }
    
    private func recordAccess(for url: URL) {
        cacheAccessTimes[url] = Date()
    }

    func preloadImages(from urlStrings: [String]) {
        let urls = urlStrings.compactMap { URL(string: $0) }
        self.urls = urls
        for url in urls {
            loadImage(for: url)
        }
        DispatchQueue.main.async {
            self.lastRefreshed = Date()
        }
    }
    
    /// Preload media items (only loads images, skips videos)
    func preloadMedia(from mediaItems: [MediaItem]) {
        let urls = mediaItems
            .filter { !$0.type.isVideo } // Only preload images
            .compactMap { URL(string: $0.url) }
        self.urls = urls
        for url in urls {
            loadImage(for: url)
        }
        DispatchQueue.main.async {
            self.lastRefreshed = Date()
        }
    }

    func refreshImages() {
        for url in urls {
            loadImage(for: url, forceRefresh: true)
        }
        DispatchQueue.main.async {
            self.lastRefreshed = Date()
        }
    }
    
    func retryImage(for url: URL) {
        loadImage(for: url, forceRefresh: true)
    }

    private func startBackgroundRefresh() {
        // Main refresh cycle - repopulate queue
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.queueBackgroundRefresh()
        }
        
        // Batch processor - continuously process queue
        Timer.scheduledTimer(withTimeInterval: batchRefreshInterval, repeats: true) { [weak self] _ in
            self?.processRefreshQueue()
        }
    }
    
    /// Queue all images for refresh (called every refreshInterval seconds)
    private func queueBackgroundRefresh() {
        // Add all URLs to queue if not already queued
        let urlsToQueue = urls.filter { url in
            !refreshQueue.contains(url) && !loading.contains(url)
        }
        
        // Prioritize recently accessed images
        let sortedUrls = urlsToQueue.sorted { url1, url2 in
            let time1 = cacheAccessTimes[url1] ?? .distantPast
            let time2 = cacheAccessTimes[url2] ?? .distantPast
            return time1 > time2
        }
        
        refreshQueue.append(contentsOf: sortedUrls)
        
        if !sortedUrls.isEmpty {
            logger.debug("Queued \(sortedUrls.count) images for refresh")
        }
    }
    
    /// Process refresh queue in small batches (called every 500ms)
    private func processRefreshQueue() {
        // Only process if we have capacity
        guard loading.count < maxConcurrentLoads else {
            return
        }
        
        // Process next batch
        let availableSlots = maxConcurrentLoads - loading.count
        let batch = Array(refreshQueue.prefix(availableSlots))
        
        if !batch.isEmpty {
            refreshQueue.removeFirst(batch.count)
            
            for url in batch {
                loadImage(for: url)
            }
            
            DispatchQueue.main.async {
                self.lastRefreshed = Date()
            }
        }
    }

    private func loadImage(for url: URL, forceRefresh: Bool = false) {
        let startTime = Date()
        
        var request = URLRequest(url: url)
        request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
        request.timeoutInterval = AppEnvironment.networkTimeout
        
        // Add conditional request headers for efficient 304 responses
        if !forceRefresh {
            if let etag = etags[url] {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            if let lastModified = lastModifieds[url] {
                request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
            }
        }
        
        DispatchQueue.main.async {
            if self.hasLoadedOnce.contains(url) {
                self.loading.insert(url)
            }
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            let duration = Date().timeIntervalSince(startTime)
            
            if let error = error {
                self.logger.error("Failed to download image for URL: \(url.absoluteString)", error: error)
                
                // Track failure
                MetricsService.shared.track(
                    event: .imageLoadFailure,
                    duration: duration,
                    tags: ["url": url.absoluteString, "error": error.localizedDescription]
                )
                
                DispatchQueue.main.async {
                    self.loading.remove(url)
                }
                return
            }
            
            // Handle 304 Not Modified - image unchanged, no work needed!
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 304 {
                self.logger.debug("Image unchanged (304) for URL: \(url.absoluteString)")
                
                MetricsService.shared.track(
                    event: .imageLoadSuccess,
                    duration: duration,
                    tags: ["changed": "false", "cached": "true"]
                )
                
                DispatchQueue.main.async {
                    self.loading.remove(url)
                    self.recordAccess(for: url)
                    self.lastRefreshed = Date()
                }
                return
            }
            
            guard let data = data, data.count > 100 else {
                self.logger.warning("Image data for URL \(url.absoluteString) is too small or missing")
                DispatchQueue.main.async {
                    self.loading.remove(url)
                }
                return
            }
            
            // Decode image off main thread
            guard let image = UIImage(data: data) else {
                self.logger.error("Failed to decode image for URL: \(url.absoluteString). Data length: \(data.count)")
                DispatchQueue.main.async {
                    self.loading.remove(url)
                }
                return
            }
            
            // Force decompression off main thread to avoid stuttering
            let decompressedImage = image.preparingForDisplay()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.warning("No HTTP response for URL: \(url.absoluteString)")
                DispatchQueue.main.async {
                    self.loading.remove(url)
                }
                return
            }
            
            let newEtag = httpResponse.allHeaderFields["Etag"] as? String
            let newLastModified = httpResponse.allHeaderFields["Last-Modified"] as? String
            
            DispatchQueue.main.async {
                let prevEtag = self.etags[url]
                let prevLastModified = self.lastModifieds[url]
                let changed: Bool = {
                    var changed = false
                    if let newEtag = newEtag {
                        if let prevEtag = prevEtag {
                            changed = newEtag != prevEtag
                        } else {
                            changed = true
                        }
                    }
                    if let newLastModified = newLastModified {
                        if let prevLastModified = prevLastModified {
                            changed = changed || (newLastModified != prevLastModified)
                        } else {
                            changed = true
                        }
                    }
                    return changed
                }()
                
                let isFirstLoad = !self.hasLoadedOnce.contains(url)
                // Use decompressed image to avoid UI lag
                self.loadedImages[url] = decompressedImage ?? image
                self.recordAccess(for: url)
                self.lastRefreshed = Date()
                self.hasLoadedOnce.insert(url)
                
                // Track successful load
                MetricsService.shared.track(
                    event: .imageLoadSuccess,
                    duration: duration,
                    tags: ["changed": changed ? "true" : "false"]
                )
                
                if changed && !isFirstLoad {
                    self.loading.remove(url)
                    self.fadingOut[url] = Date()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.fadingOut.removeValue(forKey: url)
                    }
                } else if !isFirstLoad {
                    self.loading.remove(url)
                }
                
                if let newEtag = newEtag { self.etags[url] = newEtag }
                if let newLastModified = newLastModified { self.lastModifieds[url] = newLastModified }
            }
            
            // Prune cache if needed (do outside main queue to avoid blocking)
            if self.loadedImages.count > self.maxCachedImages {
                self.pruneCache()
            }
        }.resume()
    }
}
