import Foundation
import UIKit

class ImagePreloader: ObservableObject {
    @Published var loadedImages: [URL: UIImage] = [:]
    @Published var lastRefreshed: Date = .init()
    @Published var loading: Set<URL> = []
    @Published var fadingOut: [URL: Date] = [:]
    private var urls: [URL] = []
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 5.0
    private var etags: [URL: String] = [:]
    private var lastModifieds: [URL: String] = [:]
    private var hasLoadedOnce: Set<URL> = []

    init() {
        startBackgroundRefresh()
    }

    deinit {
        timer?.invalidate()
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

    func refreshImages() {
        for url in urls {
            loadImage(for: url, forceRefresh: true)
        }
        DispatchQueue.main.async {
            self.lastRefreshed = Date()
        }
    }

    private func startBackgroundRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            print("Background refresh triggered at \(Date())")
            self?.backgroundRefresh()
        }
    }

    private func backgroundRefresh() {
        for url in urls {
            loadImage(for: url)
        }
        DispatchQueue.main.async {
            self.lastRefreshed = Date()
        }
    }

    private func loadImage(for url: URL, forceRefresh: Bool = false) {
        var request = URLRequest(url: url)
        request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .useProtocolCachePolicy
        DispatchQueue.main.async {
            if self.hasLoadedOnce.contains(url) {
                self.loading.insert(url)
            }
        }
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("[ImagePreloader] Failed to download image for URL: \(url) - Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.loading.remove(url)
                }
                return
            }
            guard let data = data, data.count > 100 else {
                print("[ImagePreloader] Image data for URL \(url) is too small or missing.")
                DispatchQueue.main.async {
                    self.loading.remove(url)
                }
                return
            }
            guard let image = UIImage(data: data) else {
                print("[ImagePreloader] Failed to decode image for URL: \(url). Data length: \(data.count)")
                DispatchQueue.main.async {
                    self.loading.remove(url)
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[ImagePreloader] No HTTP response for URL: \(url)")
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
                self.loadedImages[url] = image
                self.lastRefreshed = Date()
                self.hasLoadedOnce.insert(url)
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
        }.resume()
    }
}
