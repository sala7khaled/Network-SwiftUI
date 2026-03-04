//
//  Sentry.swift
//  Networking
//
//  Created by Salah Khaled on 04/03/2026.
//

import SwiftUI
import Combine

struct SentryEntry: Identifiable {
    let id = UUID()
    let url: String
    let method: String
    let headers: Headers
    let code: Int
    let time: TimeInterval
    var response: Data?
}

final class SentryManager: ObservableObject {
    
    static let shared = SentryManager()
    
    @Published private(set) var history: [SentryEntry] = []
    
    private init() {}
    
    func add(_ entry: SentryEntry) {
        DispatchQueue.main.async {
            self.history.insert(entry, at: 0)
        }
    }
    
    func clear() {
        history.removeAll()
    }
}

struct SentryView: View {
    
    @ObservedObject private var manager = SentryManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(manager: SentryManager = .shared) {
        self.manager = manager
    }
    
    var body: some View {
        NavigationView {
            List(manager.history) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack(alignment: .center) {
                        Text(entry.method)
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray, lineWidth: 0.5) // border color and width
                            )
                        Spacer()
                        Text(String(entry.code))
                            .foregroundColor(codeColor(for: entry.code))
                            .font(.subheadline)
                            .bold()
                    }
                    
                    Text(entry.url)
                        .font(.footnote)
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(Int(entry.time * 1000)) ms")
                        Spacer()
                        Text("{ \(entry.response?.count ?? 0) bytes }")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("sentry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("clear") {
                        manager.clear()
                    }
                    .font(.system(size: 15))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15))
                    }

                }
            }
        }
    }
    
    private func codeColor(for code: Int) -> Color {
        switch code {
        case 100..<200: return .blue
        case 200..<300: return .green
        case 300..<400: return .yellow
        case 400..<500: return .orange
        default: return .red
        }
    }
    
    static var preview: SentryManager {
        let manager = SentryManager.shared
        manager.add(SentryEntry(url: "https://www.example.com?param=value",
                                method: "GET",
                                headers: ["Accept": "application/json",
                                          "Accept-Language": "en",
                                          "Build": "application/json",
                                          "Content-Type": "1",
                                          "Device-Id": "8B6055A7-EE9F-4017-B8DE-ED0D14B01CA5",
                                          "Platform": "iOS",
                                          "Version": "1.0"],
                                code: 100,
                                time: 10,
                                response: Data("Sample response".utf8)))
        
        
        return manager
    }
}

#Preview {
    SentryView(manager: SentryView.preview)
}
