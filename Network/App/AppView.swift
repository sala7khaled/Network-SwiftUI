//
//  AppView.swift
//  Networking
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

@main
struct AppView: App {
    
    init() { Connectivity.shared.start() }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .sentry()
                .toaster()
        }
    }
}
