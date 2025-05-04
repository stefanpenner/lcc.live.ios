import Foundation
import UIKit

class ImagePreloader: ObservableObject {
    @Published var loadedImages: [URL: UIImage] = [:]
    @Published var lastRefreshed: Date = .init()
    private var urls: [URL] = []
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 5.0

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
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.loadedImages[url] = image
                    self.lastRefreshed = Date()
                }
            }
        }.resume()
    }
}
