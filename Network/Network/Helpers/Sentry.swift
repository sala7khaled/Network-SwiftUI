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
    let method: HTTPMethod
    let headers: Headers
    let code: Int
    let elapsed: TimeInterval
    let time: Date
    var body: Data?
    var response: Data?
    var error: APIError?
    var isCache: Bool = false
}

// MARK: - Manager
final class SentryManager: ObservableObject {
    
    static let shared = SentryManager()
    @Published private(set) var requests: [SentryEntry] = []
    @Published private(set) var images: [SentryEntry] = []
    
    /// Request
    func addRequest(_ entry: SentryEntry) {
        DispatchQueue.main.async {
            self.requests.insert(entry, at: 0)
        }
    }
    
    /// Image
    func addImage(_ entry: SentryEntry) {
        DispatchQueue.main.async {
            self.images.insert(entry, at: 0)
        }
    }
    
    func clear() {
        requests.removeAll()
        images.removeAll()
    }
}

// MARK: - Sentry
struct SentryView: View {
    
    // MARK: - Tab
    enum SentryTab: Int, CaseIterable, Identifiable {
        case requests = 0
        case images = 1
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .requests: return "apiRequests"
            case .images: return "imageRequests"
            }
        }
        
        var icon: String {
            switch self {
            case .requests: return "network"
            case .images: return "photo"
            }
        }
    }
    
    // MARK: - Properties
    @ObservedObject private var manager = SentryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntry: SentryEntry? = nil
    @State private var selectedImage: SentryEntry? = nil
    @State private var sentryTab: SentryTab = .requests
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedMethod: HTTPMethod? = nil
    
    
    // MARK: - Init
    init(manager: SentryManager = .shared) {
        self.manager = manager
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            content
            .navigationTitle("sentry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("selectTab", selection: $sentryTab) {
                            ForEach(SentryTab.allCases) { tab in
                                Label(String(localized: String.LocalizationValue(tab.title)), systemImage: tab.icon)
                                    .tag(tab)
                            }
                        }
                        
                        Button(role: .destructive) { manager.clear() } label: {
                            Label("clearHistory", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: sentryTab.icon)
                            .font(.system(size: 15))
                    }
                }
                
                if sentryTab == .requests {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Section {
                                Button("all") { selectedMethod = nil }
                            }
                            Picker("selectMethod", selection: $selectedMethod) {
                                ForEach(HTTPMethod.allCases, id: \.self) { method in
                                    Text(method.rawValue)
                                        .tag(method)
                                }
                            }
                        } label: {
                            
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .symbolRenderingMode(selectedMethod != nil ? .multicolor : .hierarchical)
                                    .symbolEffect(.variableColor)
                                
                                if let method = selectedMethod {
                                    Text(method.rawValue)
                                        .font(.caption)
                                        .bold()
                                        .padding(.trailing, 6)
                                }
                            }
                            
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15))
                    }
                }
            }
            .searchable(
                text: $searchText, placement: .automatic, prompt: "search"
            )
            .searchScopes($selectedMethod) {
                Text("all").tag(nil as HTTPMethod?)
                ForEach(HTTPMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method as HTTPMethod?)
                }
            }
            .focused($isSearchFocused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
        }
    }
    
    
    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        let isEmpty = sentryTab == .requests
        ? filteredRequests.isEmpty
        : filteredImages.isEmpty
        
        if isEmpty {
            emptyListView
        } else {
            switch sentryTab {
            case .requests:
                requestList
            case .images:
                imageList
            }
        }
    }
    
    // MARK: - Empty View
    @ViewBuilder
    var emptyListView: some View {
        
        let title = String(localized: String.LocalizationValue(sentryTab.title)).lowercased()
        
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: sentryTab == .requests ? "network.slash" : "rectangle.slash")
                .foregroundStyle(.secondary)
            Text(.emptySentry(title))
                .foregroundStyle(.secondary)
                .font(.caption)
            Spacer()
        }
    }
    
    
    // MARK: - Request List
    @ViewBuilder
    var requestList: some View {
        
        List {
            Section {
                Text("\(filteredRequests.filter { $0.code < 400 }.count)")
            } header: {
                Text("statistics")
                    .font(.caption)
                    .bold()
            }

            Section {
                if filteredRequests.isEmpty {
                    emptyListView
                } else {
                    ForEach(filteredRequests) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center) {
                                HStack {
                                    Text(entry.method.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.gray.opacity(0.2))
                                        .cornerRadius(6)
                                    
                                    Text(entry.endPoint)
                                        .font(.caption)
                                        .bold()
                                }
                                Spacer()
                                Text(entry.isCache ? String(localized: "cache") : String(entry.code))
                                    .foregroundColor(entry.isCache ? .green : entry.code.color())
                                    .font(.subheadline)
                                    .bold()
                            }
                            
                            Text(entry.url)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            HStack {
                                if let error = entry.error {
                                    Text(error.type.rawValue.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.red)
                                }
                                Text("\(Int(entry.elapsed * 1000)) ms")
                                Spacer()
                                Text("\(entry.time.formatted(date: .omitted, time: .standard))")
                            }
                            .font(.caption2)
                            .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedEntry = entry }
                        .copyable(text: entry.url)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $selectedEntry) { entry in
            SentryDetailView(entry: entry)
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Request List
    @ViewBuilder
    var imageList: some View {
        List(filteredImages) { entry in
            
            let cachedImage = URL(string: entry.url).flatMap { Network.shared.imageCache[$0] }
            let isCached = cachedImage != nil
            
            HStack(alignment: .center, spacing: 16) {
                
                Group {
                    if let image = cachedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo.badge.exclamationmark.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                }
                .frame(width: 84, height: 84)
                .background(.thinMaterial)
                .cornerRadius(10)
                .onTapGesture {
                    selectedImage = entry
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        Text(entry.endPoint)
                            .font(.caption)
                            .bold()
                        Spacer()
                        Text(isCached ? "cached" : "notCached")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isCached ? .green.opacity(0.2) : .red.opacity(0.2))
                            .cornerRadius(6)
                            .foregroundStyle(isCached ? .green : .red)
                    }
                    
                    Text(entry.url)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        if let error = entry.error {
                            Text(error.type.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                        }
                        Text("\(Int(entry.elapsed * 1000)) ms")
                        Spacer()
                        Text("\(entry.time.formatted(date: .omitted, time: .standard))")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
               
            }
            .copyable(text: entry.url)
        }
        .sheet(item: $selectedImage) { entry in
            if let image = URL(string: entry.url).flatMap({ Network.shared.imageCache[$0] }) {
                ImageViewer(title: entry.endPoint, image: image)
                    .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Search
    private var filteredRequests: [SentryEntry] {
        manager.requests.filter { entry in
            let matchesSearch = searchText.isEmpty ||
            entry.url.localizedCaseInsensitiveContains(searchText) ||
            entry.endPoint.localizedCaseInsensitiveContains(searchText)
            
            let matchesMethod = selectedMethod == nil || entry.method == selectedMethod
            
            return matchesSearch && matchesMethod
        }
    }
    
    private var filteredImages: [SentryEntry] {
        guard !searchText.isEmpty else { return manager.images }
        return manager.images.filter {
            $0.url.localizedCaseInsensitiveContains(searchText) ||
            $0.endPoint.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    
    
    static var preview: SentryManager {
        let manager = SentryManager.shared
        manager.addRequest(SentryEntry(url: "https://www.site.com/login?param=value",
                                       endPoint: "login",
                                       method: .GET,
                                       headers: ["Accept": "application/json",
                                                 "Accept-Language": "en",
                                                 "Build": "application/json",
                                                 "Content-Type": "1",
                                                 "Device-Id": "8B6055A7-EE9F-4017-B8DE-ED0D14B01CA5",
                                                 "Platform": "iOS",
                                                 "Version": "1.0"],
                                       code: 200,
                                       elapsed: 10,
                                       time: Date(),
                                       response: Data("Sample response".utf8),
                                       isCache: false))
        
        manager.addImage(SentryEntry(url: "https://cdn.dummyjson.com/product-images/beauty/red-lipstick/thumbnail.webp",
                                     endPoint: "thumbnail.webp",
                                     method: .GET,
                                     headers: [:],
                                     code: 200,
                                     elapsed: 0.07251596450805664,
                                     time: Date(),
                                     body: nil,
                                     response: nil, error: nil))
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
            .scrollIndicators(.hidden)
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
        
        let copyText = "[\(entry.method)] \(entry.endPoint) (code: \(entry.code))"
        let hasError = entry.error != nil
        
        return Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack {
                        Text(entry.method.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.gray.opacity(0.2))
                            .cornerRadius(6)
                        Text(entry.endPoint)
                            .font(.caption)
                            .lineLimit(nil)
                            .padding(.vertical, 4)
                    }
                    Spacer()
                    Text(entry.isCache ? String(localized: "cache") : String(entry.code))
                        .foregroundColor(entry.isCache ? .green : entry.code.color())
                        .font(.subheadline)
                        .bold()
                }
                .padding(.vertical, 4)
                
                if let error = entry.error {
                    Divider()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(error.type.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .cornerRadius(6)
                        Text(error.localize())
                            .font(.caption)
                            .lineLimit(nil)
                            .padding(.vertical, 4)
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            HStack {
                Text("request")
                    .font(.caption)
                    .bold()
                Spacer()
                Text("\(Int(entry.elapsed * 1000)) ms")
                    .font(.caption2)
            }
        }
        .applyIf(hasError) { view in
            view.copyable(title: String(localized: "error"),
                          text: "[\(entry.error!.type.rawValue.capitalized)] \(entry.error!.localize())",
                          color: .red,
                          icon: "flag.fill")
        }
        .copyable(text: copyText)
    }
    
    // MARK: - URL
    var urlSection: some View {
        let queryItems = URLComponents(string: entry.url)?.queryItems
        
        return Section {
            
            VStack(alignment: .leading, spacing: 10) {
                Text(API.baseUrl + entry.endPoint)
                    .font(.caption)
                    .lineLimit(nil)
                    .padding(.vertical, 3)
                
                if let queryItems, !queryItems.isEmpty {
                    Divider()
                    ChipListView(parameters: queryItems)
                }
            }
            
        } header: {
            HStack {
                Text("url")
                    .font(.caption)
                    .bold()
                Spacer()
                if let queryItems, !queryItems.isEmpty {
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
    SentryDetailView(entry: SentryEntry(url: "https://dogapi.dog/api/v2/breeds?id=&attributes=ssadddadadad8ass&type=",
                                        endPoint: "login",
                                        method: .GET,
                                        headers: ["Accept": "application/json",
                                                  "Accept-Language": "en",
                                                  "Build": "application/js",
                                                  "Content-Type": "1",
                                                  "Authorization": "Bearer abcdefghijklmn",
                                                  "Device-Id": "8B6055A7-EE9F-4017-B8DE-ED0D14B01CA5",
                                                  "Platform": "iOS",
                                                  "Version": ""],
                                        code: 200,
                                        elapsed: 10,
                                        time: Date(),
                                        response: Data("sample response".utf8),
                                        error: APIError(type: .server)))
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
                ? ($0.value == "" ? "__" : $0.value.truncateToken())
                : ($0.value == "" ? "__" : $0.value)
            )}
    }
    
    init(parameters: [URLQueryItem], sorted: Bool = true) {
        let mapped = parameters.map { ChipItem(key: $0.name, value: ($0.value == "" ? "__" : $0.value) ?? "__") }
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
                    .foregroundColor(item.value == "__" ? .red : .secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, itemSpace)
            .padding(.vertical, 6)
            .background(.gray.opacity(0.2))
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
            let itemWidth = estimateWidth(for: item)
            
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
        let text = (item as? ChipItem).map { $0.key + $0.value } ?? "\(item.id)"
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10, weight: .medium)] // Same font as ChipItem
        return text.size(withAttributes: attributes).width + (itemSpace * 2) + itemSpace
    }
}


// MARK: - Image Viewer
fileprivate struct ImageViewer: View {
    
    let title: String
    let image: UIImage
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
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
}
