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
