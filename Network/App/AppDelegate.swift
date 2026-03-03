//
//  AppDelegate.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

@main
struct AppDelegate: App {
    
    init() {
        Connectivity.start()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
