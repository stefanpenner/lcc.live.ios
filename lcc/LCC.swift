//
//  LCC.swift
//  lcc
//
//  Created by Stefan Penner on 4/30/25.
//

import SwiftUI

@main
struct LCC: App {
    @StateObject private var apiService = APIService()
    @StateObject private var preloader = ImagePreloader()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init() {
        // Initialize metrics service
        _ = MetricsService.shared
        
        // Print configuration in debug mode
        AppEnvironment.printConfiguration()
        
        // Track app launch
        MetricsService.shared.track(
            event: .appLaunch,
            tags: [
                "version": AppEnvironment.appVersion,
                "build": AppEnvironment.buildNumber
            ]
        )
        
        Logger.app.info("🚀 App launched - Version \(AppEnvironment.fullVersion)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiService)
                .environmentObject(preloader)
                .environmentObject(networkMonitor)
                .background(Color.black.ignoresSafeArea(.all))
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
        .background(Color.black.ignoresSafeArea(.all))
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
