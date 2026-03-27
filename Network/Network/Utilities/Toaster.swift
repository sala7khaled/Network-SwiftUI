//
//  Toaster.swift
//  Networking
//
//  Created by Salah Khaled on 19/03/2026.
//

import SwiftUI
import Combine

enum ToastEntry: Equatable {
    
    case `default`
    case success(_ icon: String? = nil)
    case error(_ icon: String? = nil)
    case copy
    case online
    case offline
    
    var icons: (String, String) {
        switch self {
        case .default: ("info.circle", "info.circle")
        case .success(let icon): (icon ?? "info.circle", "checkmark.circle")
        case .error(let icon): (icon ?? "info.square", "xmark.circle")
        case .copy: ("square.on.square", "checkmark.circle")
        case .online: ("wifi.slash", "wifi")
        case .offline: ("wifi", "wifi.slash")
        }
    }
    
    var color: Color {
        switch self {
        case .default, .copy: .primary
        case .success, .online: .green
        case .error, .offline: .red
        }
    }
    
}

// MARK: - Toaster
final class Toaster: ObservableObject {
    static let shared = Toaster()
    
    // MARK: - Properties
    private var currentTask: DispatchWorkItem?
    @Published fileprivate var message: String = ""
    @Published fileprivate var isShowing: Bool = false
    @Published fileprivate var type: ToastEntry = .default
    
    // MARK: - Toast
    func show(type: ToastEntry = .default, _ message: String, _ duration: TimeInterval = 3) {

        currentTask?.cancel()
        self.isShowing = false

        self.type = type
        self.message = message
        
        withAnimation {
            self.isShowing = false
            self.isShowing = true
        }
        
        let task = DispatchWorkItem {
            withAnimation { self.isShowing = false }
        }
        
        currentTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

// MARK: - Toast View
struct ToastView: View {
    @ObservedObject var manager: Toaster = .shared
    @State private var isAnimated = false
    
    var body: some View {
        if manager.isShowing {
            HStack(spacing: 14) {
                Image(systemName: isAnimated ? manager.type.icons.1 : manager.type.icons.0)
                    .font(.system(size: 18))
                    .frame(width: 20, height: 20, alignment: .center)
                    .if(manager.type == .default) {
                        $0.symbolEffect(.bounce.up.byLayer, options: .repeat(.periodic(delay: 1.0)))
                    }
                    .if(manager.type != .default) {
                        $0.contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                    }
                Text(manager.message)
                    .font(.footnote)
            }
            .padding()
            .if(manager.type == .default) {
                $0.background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                  .colorInvert()
            }
            .if(manager.type != .default) {
                $0.colorInvert()
                  .background(manager.type.color, in: RoundedRectangle(cornerRadius: 20))
                
            }
            .padding(.top, 10) // Screen padding
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { isAnimated = true }
                }
            }
            .onDisappear { isAnimated = false }
        }
    }
}

#Preview {
    let toaster: Toaster =  {
       let toaster = Toaster()
        toaster.isShowing = true
        toaster.message = "This is a message"
        toaster.type = .success("lock")
        return toaster
    }()
    
    ToastView(manager: toaster)
}
