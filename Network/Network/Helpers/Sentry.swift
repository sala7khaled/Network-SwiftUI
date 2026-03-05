//
//  Sentry.swift
//  Networking
//
//  Created by Salah Khaled on 04/03/2026.
//

import SwiftUI
import Combine

// MARK: - Model
struct SentryEntry: Identifiable {
    let id = UUID()
    let url: String
    let endPoint: String
    let method: String
    let headers: Headers
    let code: Int
    let time: TimeInterval
    var response: Data?
}

// MARK: - Manager
final class SentryManager: ObservableObject {
    
    static let shared = SentryManager()
    @Published private(set) var requests: [SentryEntry] = []
    
    func add(_ entry: SentryEntry) {
        DispatchQueue.main.async {
            self.requests.insert(entry, at: 0)
        }
    }
    
    func clear() {
        requests.removeAll()
    }
}

// MARK: - Sentry
struct SentryView: View {
    
    @ObservedObject private var manager = SentryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntry: SentryEntry? = nil
    
    init(manager: SentryManager = .shared) {
        self.manager = manager
    }
    
    var body: some View {
        NavigationView {
            List(manager.requests) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack(alignment: .center) {
                        HStack {
//                            TagItem(value: entry.method)
                            
                            Text(entry.method)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                            
                            Text(entry.endPoint)
                                .font(.caption)
                                .bold()
                        }
                        Spacer()
                        Text(String(entry.code))
                            .foregroundColor(entry.code.color())
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
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedEntry = entry
                }
            }
            .navigationTitle("sentry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("clear", action: manager.clear)
                        .font(.system(size: 15))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15))
                    }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                SentryDetailView(entry: entry)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    static var preview: SentryManager {
        let manager = SentryManager.shared
        manager.add(SentryEntry(url: "https://www.site.com/login?param=value",
                                endPoint: "login",
                                method: "GET",
                                headers: ["Accept": "application/json",
                                          "Accept-Language": "en",
                                          "Build": "application/json",
                                          "Content-Type": "1",
                                          "Device-Id": "8B6055A7-EE9F-4017-B8DE-ED0D14B01CA5",
                                          "Platform": "iOS",
                                          "Version": "1.0"],
                                code: 200,
                                time: 10,
                                response: Data("Sample response".utf8)))
        
        
        return manager
    }
}

#Preview {
    SentryView(manager: SentryView.preview)
}



// MARK: - Sentry Detail
fileprivate struct SentryDetailView: View {
    let entry: SentryEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                requestSection
                urlSection
                headersSection
                responseSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(entry.endPoint)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15))
                    }
                }
            }
        }
    }
    
    // MARK: - Request
    var requestSection: some View {
        Section {
            HStack {
                Text(entry.method)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                Spacer()
                Text("\(entry.code)")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(entry.code.color())
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("request")
                    .font(.caption)
                    .bold()
                Spacer()
                Text("\(Int(entry.time * 1000)) ms")
                    .font(.caption2)
            }
        }
    }
    
    // MARK: - URL
    var urlSection: some View {
        let queryItems = URLComponents(string: entry.url)?.queryItems
        
        return Section {
            ChipListView(url: (API.baseUrl + entry.endPoint), parameters: queryItems ?? [])
        } header: {
            HStack {
                Text("url")
                    .font(.caption)
                    .bold()
                Spacer()
                if let queryItems = queryItems, !queryItems.isEmpty {
                    Text("\(queryItems.count) param\(queryItems.count > 1 ? "s" : "")")
                        .font(.caption2)
                }
            }
        }
    }
    
    // MARK: - Headers
    var headersSection: some View {
        
        let headers = entry.headers
        guard !headers.isEmpty else { return AnyView(EmptyView()) }
        
        let hasAuth = headers.keys.contains {
            $0.localizedCaseInsensitiveContains(APIHeader.authorization)
        }
        
        return AnyView(
            Section {
                ChipListView(headers: headers)
            } header: {
                HStack {
                    Text("headers")
                        .font(.caption)
                        .bold()
                    if hasAuth {
                        Text("🔐")
                            .font(.caption)
                    }
                    Spacer()
                    Text("\(headers.count) header\(headers.count > 1 ? "s" : "")")
                        .font(.caption2)
                }
            }
        )
    }
    
    // MARK: - Response
    var responseSection: some View {
        Section {
            Text(entry.response.prettyPrint().truncated(4000))
                .font(.caption)
                .lineLimit(nil)
        } header: {
            HStack {
                Text("response")
                    .font(.caption)
                    .bold()
                Spacer()
                Text("\(entry.response?.count ?? 0) bytes")
                    .font(.caption2)
            }
        }
    }
}

#Preview("Detail") {
    SentryDetailView(entry: SentryEntry(url: "https://www.site.com/login?param=value",
                                        endPoint: "login",
                                        method: "GET",
                                        headers: ["Accept": "application/json",
                                                  "Accept-Language": "en",
                                                  "Build": "application/json",
                                                  "Content-Type": "1",
                                                  "Device-Id": "8B6055A7-EE9F-4017-B8DE-ED0D14B01CA5",
                                                  "Platform": "iOS",
                                                  "Version": "1.0"],
                                        code: 200,
                                        time: 10,
                                        response: Data("sample response".utf8)))
}

// MARK: - Widget
fileprivate struct ChipListView: View {
    private let url: String?
    private let items: [(key: String, value: String)]
    
    // MARK: - Headers Init
    init(headers: [String: String]) {
        self.url = nil
        
        self.items = headers
            .sorted { $0.key < $1.key }
            .map {
                ($0.key,
                 $0.key.contains(APIHeader.authorization)
                    ? $0.value.truncateToken()
                    : $0.value)
            }
    }
    
    // MARK: - Parameters Init
    init(url: String, parameters: [URLQueryItem], sorted: Bool = true) {
        let mapped = parameters.map { ("? \($0.name) =", $0.value ?? "__") }
        let entries = sorted
        ? mapped.sorted { $0.0 < $1.0 }
        : mapped
        
        self.url = url
        self.items = entries
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let url {
                    Text(url)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 6)
                        .background(.clear)
                }
                ForEach(items, id: \.key) { item in
                    HStack(spacing: 4) {
                        Text(item.key)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(item.value)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 20)
        }
        .listRowInsets(EdgeInsets())
    }
}
