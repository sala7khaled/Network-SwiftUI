//
//  AppDelegate.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

@main
struct AppDelegate: App {
    
    @State private var showSentry = false
    
    init() {
        Connectivity.start()
    }
    
    var body: some Scene {
        WindowGroup {
            
            HomeView()
                .onLongPressGesture(minimumDuration: 0.2) {
                    #if DEBUG
                    showSentry = true
                    #endif
                }
                .fullScreenCover(isPresented: $showSentry) {
                    SentryView()
                }
        }
    }
}
