//
//  AppDelegate.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

@main
struct AppDelegate: App {
    
    #if DEBUG
    @State private var showSentry = false
    #endif
    
    init() {
        Connectivity.start()
    }
    
    var body: some Scene {
        WindowGroup {
            
            #if DEBUG
            MainView()
//                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.2) {
                    showSentry = true
                }
                .fullScreenCover(isPresented: $showSentry) {
                    SentryView()
                }
            #else
            MainView()
            #endif
            
        }
    }
}
