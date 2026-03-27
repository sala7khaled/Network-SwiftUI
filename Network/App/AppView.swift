//
//  AppView.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

@main
struct AppView: App {
    
    @State private var showSentry = true
    
    init() { Connectivity.shared.start() }
    
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
                        .overlay(alignment: .top) {
                            ToastView()
                        }
                        
                }
                .overlay(alignment: .top) {
                    ToastView()
                }
        }
    }
}
