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
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init() {
        // Initialize metrics service
        _ = MetricsService.shared
        
        // Print configuration in debug mode
        Environment.printConfiguration()
        
        // Track app launch
        MetricsService.shared.track(
            event: .appLaunch,
            tags: [
                "version": Environment.appVersion,
                "build": Environment.buildNumber
            ]
        )
        
        Logger.app.info("🚀 App launched - Version \(Environment.fullVersion)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiService)
                .environmentObject(preloader)
                .environmentObject(networkMonitor)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var preloader: ImagePreloader
    
    var body: some View {
        MainView(
            mediaItems: (
                lcc: apiService.lccMedia,
                bcc: apiService.bccMedia
            )
        )
        .onChange(of: apiService.lccMedia) { oldValue, newValue in
            if !newValue.isEmpty {
                preloader.preloadMedia(from: newValue)
            }
        }
        .onChange(of: apiService.bccMedia) { oldValue, newValue in
            if !newValue.isEmpty {
                preloader.preloadMedia(from: newValue)
            }
        }
    }
}
