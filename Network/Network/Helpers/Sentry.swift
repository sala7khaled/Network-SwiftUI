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
    var body: Data?
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
                bodySection
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
        .copyable(text: "[\(entry.method)] \(entry.endPoint): \(entry.code)")
    }
    
    // MARK: - URL
    var urlSection: some View {
        let queryItems = URLComponents(string: entry.url)?.queryItems
        
        return Section {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(API.baseUrl + entry.endPoint)
                    .font(.caption)
                    .lineLimit(nil)
                    .padding(.vertical, 2)
                Divider()
                ChipListView(parameters: queryItems ?? [])
            }
            
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
        .copyable(text: entry.url)
    }
    
    // MARK: - Headers
    var headersSection: some View {
        
        let headers = entry.headers
        guard !headers.isEmpty else { return AnyView(EmptyView()) }
        
        let hasAuth = headers.keys.contains { $0.contains(APIHeader.authorization) }
        
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
                .invalidatableContent()
                .applyIf(hasAuth) { view in
                    view.copyable(title: String(localized: "token"),
                                  text: headers[APIHeader.authorization] ?? "",
                                  color: .orange,
                                  icon: "lock")
                }
                .copyable(text: headers.sorted { $0.key < $1.key }.map { "[\($0.key): \($0.value)]" }.joined(separator: "\n"))
        )
    }
    
    // MARK: - Body
    var bodySection: some View {
        
        guard let body = entry.body else { return AnyView(EmptyView()) }
        
        return AnyView(
            Section {
                Text(entry.body.prettyPrint().truncated(500))
                    .font(.caption)
                    .lineLimit(nil)
            } header: {
                HStack {
                    Text("body")
                        .font(.caption)
                        .bold()
                    Spacer()
                    Text("\(body.count) bytes")
                        .font(.caption2)
                }
            }.copyable(text: entry.body.prettyPrint().truncated(500))
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
        .copyable(text: entry.response.prettyPrint().truncated(4000))
    }
}

#Preview("Detail") {
    SentryDetailView(entry: SentryEntry(url: "https://www.site.com/login?param1=value?param2=value",
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

// MARK: - Chip List View
fileprivate struct ChipItem: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}
fileprivate struct ChipListView: View {
    private let items: [ChipItem]
    private let itemSpace: CGFloat = 8
    
    init(headers: [String: String]) {
        self.items = headers
            .sorted { $0.key < $1.key }
            .map { ChipItem(
                key: $0.key,
                value: $0.key.contains(APIHeader.authorization)
                ? $0.value.truncateToken()
                : $0.value
            )}
    }
    
    init(parameters: [URLQueryItem], sorted: Bool = true) {
        let mapped = parameters.map { ChipItem(key: "? \($0.name) =", value: $0.value ?? "__") }
        self.items = sorted
        ? mapped.sorted { $0.key < $1.key }
        : mapped
    }
    
    var body: some View {
        FlexibleView(items: items, itemSpace: itemSpace) { item in
            HStack(spacing: 6) {
                Text(item.key)
                    .font(.system(size: 10))
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(item.value)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, itemSpace)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(6)
        }
    }
}

// MARK: - Flexible View
fileprivate struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Identifiable {
    
    let items: Data
    let itemSpace: CGFloat
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var maxWidth: CGFloat = 0
    
    init(items: Data, itemSpace: CGFloat, spacing: CGFloat = 6,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.itemSpace = itemSpace
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        generateContent(in: maxWidth)
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { maxWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newWidth in
                        maxWidth = newWidth
                    }
            })
            .padding(.vertical, 2)
    }
    
    private func generateContent(in totalWidth: CGFloat) -> some View {
        var widthSoFar: CGFloat = 0
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        
        for item in items {
            let itemWidth = estimateWidth(for: item) + spacing
            
            if widthSoFar + itemWidth > totalWidth && totalWidth > 0 {
                currentRow += 1
                rows.append([])
                widthSoFar = 0
            }
            
            rows[currentRow].append(item)
            widthSoFar += itemWidth
        }
        
        return VStack(alignment: .leading, spacing: spacing) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    ForEach(rows[rowIndex]) { content($0) }
                }
            }
        }
    }
    
    private func estimateWidth(for item: Data.Element) -> CGFloat {
        let text: String
        if let chip = item as? ChipItem {
            text = chip.key + chip.value
        } else {
            text = "\(item.id)"
        }
        
        let width = width(of: text, usingFont: .systemFont(ofSize: 10)) + (itemSpace * 2)
        
        print("\(text)  \(width)")
        return width
    }
    
    private func width(of text: String, usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return text.size(withAttributes: attributes).width
    }
}
