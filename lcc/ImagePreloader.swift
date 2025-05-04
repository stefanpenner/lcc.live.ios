import Foundation
import UIKit

class ImagePreloader: ObservableObject {
    @Published var loadedImages: [URL: UIImage] = [:]
    
    func preloadImages(from urls: [String]) {
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, let image = UIImage(data: data) else {
                    print("Failed to load image from URL: \(urlString)")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.loadedImages[url] = image
                    print("Successfully loaded image: \(urlString)")
                }
            }.resume()
        }
    }
}
