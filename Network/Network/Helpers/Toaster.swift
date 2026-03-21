//
//  Toaster.swift
//  Networking
//
//  Created by Salah Khaled on 19/03/2026.
//

import SwiftUI
import Combine
import ActivityKit
import WidgetKit

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

// MARK: - Toaster
final class Toaster: ObservableObject {
    static let shared = Toaster()
    
    // MARK: - Properties
    @Published var message: String = ""
    @Published var isShowing: Bool = false
    
    // MARK: - Toast
    func toast(_ message: String, duration: TimeInterval = 3) {
        dynamicIsland(message)
//        self.message = message
//        withAnimation { self.isShowing = true }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
//            withAnimation { self.isShowing = false }
//        }
    }
    
    func dynamicIsland(_ message: String) {
        
        if #available(iOS 16.1, *) {
//        if true {
            startLiveActivity()
        } else {
            toast(message)
        }
        
        
    }
    
    func startLiveActivity() {
        let initialContentState = ToastActivityAttributes.ContentState(progress: 0.0, message: "hhhh")
        let activityAttributes = ToastActivityAttributes(title: "Your Activity")
        
        do {
            let activity = try Activity<ToastActivityAttributes>.request(
                attributes: activityAttributes,
                contentState: initialContentState,
                pushType: nil // Optional: Use if you want to push updates from a server
            )
            print("Live activity started: \(activity.id)")
        } catch {
            print("Error starting live activity: \(error.localizedDescription)")
        }
    }
    
    func updateLiveActivity(progress: Double) {
        Task {
            for activity in Activity<ToastActivityAttributes>.activities {
                let updatedState = ToastActivityAttributes.ContentState(progress: progress, message: "kkkkk")
                await activity.update(using: updatedState)
            }
        }
    }
    
//    @available(iOS 16.1, *)
//    func endLiveActivity() {
//        Task {
//            for activity in Activity<ToastActivityAttributes>.activities {
//                await activity.end(dismissalPolicy: .immediate)
//            }
//        }
//    }
}

// MARK: - Activity Attributes
struct ToastActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var progress: Double
        var message: String
    }
    
    var title: String
}

// MARK: - Widget / Dynamic Island
struct MyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ToastActivityAttributes.self) { context in
            // Lock screen / notification view
            VStack(alignment: .leading) {
                Text(context.state.message)
                ProgressView(value: context.state.progress)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.message)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                }
            } compactLeading: {
                Text("Toast")
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))%")
            } minimal: {
                Text("🔥")
            }
        }
    }
}
