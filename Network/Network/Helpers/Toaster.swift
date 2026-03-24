//
//  Toaster.swift
//  Networking
//
//  Created by Salah Khaled on 19/03/2026.
//

import SwiftUI
import Combine

// MARK: - Toaster
final class Toaster: ObservableObject {
    static let shared = Toaster()
    
    // MARK: - Properties
    @Published fileprivate var message: String = ""
    @Published fileprivate var isShowing: Bool = false
    
    // MARK: - Toast
    func show(_ message: String, duration: TimeInterval = 3) {
        
        guard !isShowing else { return }
        
        self.message = message
        withAnimation { self.isShowing = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation { self.isShowing = false }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    @ObservedObject var manager: Toaster = .shared
    @State private var isAnimated = false
    
    var body: some View {
        if manager.isShowing {
            HStack(spacing: 14) {
                Image(systemName: isAnimated ? "checkmark.circle" : "square.on.square")
                    .font(.system(size: 18))
                    .frame(width: 20, alignment: .center)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                    .foregroundStyle(isAnimated ? .purple : .primary)
                Text(manager.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .transition(.move(edge: .top).combined(with: .opacity))
            .colorInvert()
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
        toaster.message = "Copied to clipboard"
        return toaster
    }()
    
    ToastView(manager: toaster)
}
