//
//  LCC.swift
//  lcc
//
//  Created by Stefan Penner on 4/30/25.
//

import SwiftUI

@main
struct LCC
: App {
    @StateObject private var apiService = APIService()
    @StateObject private var preloader = ImagePreloader()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiService)
                .environmentObject(preloader)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var preloader: ImagePreloader
    
    var body: some View {
        MainView(
            images: (
                lcc: apiService.lccImages,
                bcc: apiService.bccImages
            )
        )
        .onChange(of: apiService.lccImages) { oldValue, newValue in
            if !newValue.isEmpty {
                preloader.preloadImages(from: newValue)
            }
        }
        .onChange(of: apiService.bccImages) { oldValue, newValue in
            if !newValue.isEmpty {
                preloader.preloadImages(from: newValue)
            }
        }
    }
}
