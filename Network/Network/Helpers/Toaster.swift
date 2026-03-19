//
//  Toaster.swift
//  Networking
//
//  Created by Salah Khaled on 19/03/2026.
//

import SwiftUI
import Combine
import ActivityKit

// MARK: - Toaster
final class Toaster: ObservableObject {
    static let shared = Toaster()
    
    @Published var message: String = ""
    @Published var isShowing: Bool = false
    
    func toast(_ message: String, duration: TimeInterval = 3) {
        self.message = message
        withAnimation { self.isShowing = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation { self.isShowing = false }
        }
    }
    
    func dynamicIsland(_ message: String) {
        
        guard #available(iOS 16.1, *) else {
            toast(message)
            return
        }
        
        // Activity
    }
}

// MARK: - Toast View
struct ToastView: View {
    @ObservedObject var manager: Toaster = .shared
    
    var body: some View {
        if manager.isShowing {
            Text(manager.message)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.green, in: Capsule())
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(radius: 2)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 10)
        }
    }
}

//@available(iOS 16.1, *)
//func startDynamicIslandToast(message: String) {
//    // Ensure Live Activities are allowed
//    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
//    
//    // Attributes for the Live Activity
//    let attributes = CopyActivityAttributes(title: "Copied")
//    let contentState = CopyActivityAttributes.ContentState(message: message)
//    
//    do {
//        // Wrap content in ActivityContent
//        let content = ActivityContent(state: contentState, staleDate: Date())
//        let activity = try Activity<CopyActivityAttributes>.request(
//            attributes: attributes,
//            content: content,
//            pushType: nil
//        )
//        
//        // Automatically end after 1.5 seconds
//        Task {
//            try? await Task.sleep(nanoseconds: 1_500_000_000)
//            await activity.end(dismissalPolicy: .immediate) // Fully qualified now
//        }
//    } catch {
//        print("Failed to start Live Activity: \(error)")
//    }
//    }
