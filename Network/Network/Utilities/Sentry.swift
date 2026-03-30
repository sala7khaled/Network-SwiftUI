//
//  Sentry.swift
//  Networking
//
//  Created by Salah Khaled on 04/03/2026.
//

import SwiftUI
import Combine
import Charts

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
    
    func add(_ entry: SentryEntry, to list: SentryView.SentryTab) {
        DispatchQueue.main.async {
            switch list {
            case .requests:
                self.requests.insert(entry, at: 0)
            case .images:
                self.images.insert(entry, at: 0)
            }
        }
    }
    
    func clear() {
        requests.removeAll()
        images.removeAll()
    }
}

// MARK: - Sentry
struct SentryView: View {
    
    // MARK: - Models
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
    
    private struct StatItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        var color: Color = .primary
    }
    
    // MARK: - Properties
    @ObservedObject private var manager = SentryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEntry: SentryEntry?
    @State private var sentryTab: SentryTab = .requests
    @State private var searchText = ""
    @State private var selectedMethod: HTTPMethod? = nil
    @State private var showChart = false
    @State private var isPortrait = true
    
    
    // MARK: - Init
    init(manager: SentryManager = .shared) {
        self.manager = manager
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            Group {
                if isPortrait {
                    NavigationView {
                        List {
                            chartSection
                            currentSection
                        }
                        .scrollIndicators(.hidden)
                        .listStyle(.insetGrouped)
                        .navigationTitle("sentry")
                        .toolbar(removing: .sidebarToggle)
                        .toolbar { mainToolbar }
                        .modifier(SearchModifier(searchText: $searchText, selectedMethod: $selectedMethod))
                        .modifier(SheetModifier(selectedEntry: $selectedEntry, sentryTab: $sentryTab))
                    }
                } else { // Landscape
                    NavigationStack {
                        NavigationSplitView {
                            VStack(alignment: .center, spacing: 20) {
                                Text("statistics")
                                    .font(.caption)
                                    .opacity(0.5)
                                    .padding(.top, 20)
                                Divider()
                                    .ignoresSafeArea()
                                chartSection
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                
                            }
                            .toolbar(removing: .sidebarToggle)
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                            
                        } detail: {
                            List {
                                currentSection
                            }
                            .scrollIndicators(.hidden)
                            .listStyle(.insetGrouped)
                            .contentMargins(.top, 0, for: .scrollContent)
                            .toolbar(.hidden)
                            .toolbar(removing: .sidebarToggle)
                            .modifier(SearchModifier(searchText: $searchText, selectedMethod: $selectedMethod))
                            .modifier(SheetModifier(selectedEntry: $selectedEntry, sentryTab: $sentryTab))
                        }
                        .navigationTitle("sentry")
                        .toolbar { mainToolbar }
                    }
                    
                }
            }
            .onAppear { isPortrait = geo.size.height > geo.size.width }
            .onChange(of: geo.size) { _, newSize in isPortrait = newSize.height > newSize.width }
        }
    }
    
    
    // MARK: - Content
    @ViewBuilder
    private var currentSection: some View {
        let isEmpty = sentryTab == .requests
        ? requestArray.isEmpty
        : imageArray.isEmpty
        
        if isEmpty {
            emptySection
        } else {
            switch sentryTab {
            case .requests: requestSection
            case .images: imageSection
            }
        }
    }
    
    
    // MARK: - Modifiers
    private struct SearchModifier: ViewModifier {
        @Binding var searchText: String
        @Binding var selectedMethod: HTTPMethod?
        
        func body(content: Content) -> some View {
            content
                .searchable(text: $searchText, placement: .automatic, prompt: "search")
                .searchScopes($selectedMethod) {
                    Text("all").tag(nil as HTTPMethod?)
                        .font(.footnote)
                    
                    ForEach(HTTPMethod.allCases, id: \.self) { method in
                        Text(method.rawValue)
                            .tag(method as HTTPMethod?)
                            .font(.footnote)
                    }
                }
        }
    }
    
    private struct SheetModifier: ViewModifier {
        @Binding var selectedEntry: SentryEntry?
        @Binding var sentryTab: SentryTab
        
        func body(content: Content) -> some View {
            content
                .sheet(item: $selectedEntry) { entry in
                    if sentryTab == .requests {
                        SentryDetailView(entry: entry)
                            .presentationDetents([.large])
                        
                    } else if sentryTab == .images, let image = URL(string: entry.url).flatMap({ Network.shared.imageCache[$0] }) {
                        ImageViewer(title: entry.endPoint.capitalized, image: image)
                            .presentationDetents([.medium])
                    }
                }
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var mainToolbar: some ToolbarContent {
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
            }
        }
        
        if sentryTab == .requests {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button("all") { selectedMethod = nil }
                    
                    Picker("selectMethod", selection: $selectedMethod) {
                        ForEach(HTTPMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 15, weight: .semibold))
                            .symbolRenderingMode(selectedMethod != nil ? .multicolor : .hierarchical)
                            .if(selectedMethod != nil) { $0.symbolEffect(.variableColor) }
                        
                        if let method = selectedMethod {
                            Text(method.rawValue)
                                .font(.caption.bold())
                                .padding(.trailing, 6)
                        }
                    }
                }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
            }
        }
    }
    
    // MARK: - Empty Section
    @ViewBuilder
    var emptySection: some View {
        let title = String(localized: String.LocalizationValue(sentryTab.title)).lowercased()
        
        Section {
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: sentryTab == .requests ? "network.slash" : "rectangle.slash")
                        .foregroundStyle(.red)
                    VStack {
                        Text(.emptyTitle(title))
                        Text(.emptyDesc)
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
                Spacer()
            }
        }
        .listRowBackground(Color.clear)
    }
    
    
    // MARK: - Chart Section
    @ViewBuilder
    var chartSection: some View {
        
        let entries = sentryTab == .requests ? requestArray : imageArray
        let total = entries.count
        let totalTime = entries.map(\.elapsed).reduce(0, +)
        let avgTime = total == 0 ? 0 : totalTime / Double(total)
        
        /// Requests
        let successCount = entries.filter { (200...299).contains($0.code) }.count
        let successPercent = total == 0 ? 0 : Int((Double(successCount) / Double(total)) * 100)
        
        /// Images
        let cachedCount = entries.filter {
            guard let url = URL(string: $0.url) else { return false }
            return Network.shared.imageCache[url] != nil
        }.count
        let cachedPercent = total == 0 ? 0 : Int((Double(cachedCount) / Double(total)) * 100)
        
        /// Statistics
        let statsData: [StatItem] = [
            .init(title: String(localized: sentryTab == .requests ? "requests" : "images"), value: "\(total)"),
            .init(title: String(localized: sentryTab == .requests ? "success" : "cached"), value: sentryTab == .requests ? "\(successPercent)%" : "\(cachedPercent)%"),
            .init(title: String(localized: "avgTime"), value: Int(avgTime * 1000).formatted() + " ms"),
            .init(title: String(localized: "total"), value: Int(totalTime * 1000).formatted() + " ms")
        ]
        
        /// Chart Data
        let chartData: [StatItem] = {
            switch sentryTab {
            case .requests:
                return [.init(title: String(localized: "requests"), value: String(total), color: .blue),
                        .init(title: String(localized: "success"), value: String(successCount), color: .green),
                        .init(title: String(localized: "failed"), value: String(total - successCount), color: .red)]
                
            case .images:
                return [.init(title: String(localized: "images"), value: String(total), color: .blue),
                        .init(title: String(localized: "cached"), value: String(cachedCount), color: .green),
                        .init(title: String(localized: "notCached"), value: String(total - cachedCount), color: .red)]
            }
        }()
        
        /// View
        Section {
            HStack(spacing: 2) {
                ForEach(statsData) { item in
                    VStack {
                        Text(item.value)
                            .font(.caption.bold())
                            .foregroundStyle(item.color)
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .contentShape(Rectangle())
            
            if !isPortrait || showChart {
                Chart(chartData) { item in
                    BarMark(x: .value("value", Double(item.value) ?? 0), y: .value("type", item.title))
                        .foregroundStyle(item.color)
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text(item.value)
                                .font(.caption2.bold())
                        }
                }
                .listRowSeparator(.hidden)
            }
            
        } header: {
            if isPortrait {
                Button {
                    withAnimation(.linear(duration: 0)) { showChart.toggle() }
                } label: {
                    HStack {
                        Text("statistics")
                            .font(.caption.bold())
                        Spacer()
                        HStack {
                            Text(showChart ? "hide" : "more")
                                .font(.caption)
                            Image(systemName: showChart ? "chevron.up" : "chevron.down")
                        }
                    }
                    .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .if(isPortrait) {
            $0.onTapGesture { withAnimation(.linear(duration: 0)) { showChart.toggle() } }
        }
    }
    
    
    // MARK: - Request Section
    @ViewBuilder
    var requestSection: some View {
        Section {
            ForEach(requestArray) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        HStack {
                            TextChip(title: entry.method.rawValue)
                            Text(entry.endPoint.capitalized)
                                .font(.caption.bold())
                        }
                        Spacer()
                        Text(entry.isCache ? String(localized: "cached") : String(entry.code))
                            .foregroundColor(entry.isCache ? .green : entry.code.color())
                            .font(.subheadline.bold())
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
                .copyable(title: String(localized: "curl"),
                          text: entry.curlString,
                          icon: "curlybraces.square.fill")
            }
        }
    }
    
    // MARK: - Request Section
    @ViewBuilder
    var imageSection: some View {
        
        Section {
            ForEach(imageArray) { entry in
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            Text(entry.endPoint.capitalized)
                                .font(.caption.bold())
                            Spacer()
                            TextChip(title: isCached ? "cached" : "notCached",
                                     color: isCached ? .green : .red)
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
                .contentShape(Rectangle())
                .onTapGesture { selectedEntry = entry }
                .copyable(text: entry.url)
            }
        }
    }
    
    // MARK: - Search
    private var requestArray: [SentryEntry] {
        manager.requests.filter { entry in
            let matchesSearch = searchText.isEmpty ||
            entry.url.localizedCaseInsensitiveContains(searchText) ||
            entry.endPoint.localizedCaseInsensitiveContains(searchText)
            
            let matchesMethod = selectedMethod == nil || entry.method == selectedMethod
            
            return matchesSearch && matchesMethod
        }
    }
    
    private var imageArray: [SentryEntry] {
        guard !searchText.isEmpty else { return manager.images }
        return manager.images.filter {
            $0.url.localizedCaseInsensitiveContains(searchText) ||
            $0.endPoint.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    
    
    static var preview: SentryManager {
        let manager = SentryManager.shared
        manager.add(SentryEntry(url: "https://www.site.com/login?param=value",
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
                                isCache: false), to: .requests)
        
        manager.add(SentryEntry(url: "https://cdn.dummyjson.com/product-images/beauty/red-lipstick/thumbnail.webp",
                                endPoint: "thumbnail.webp",
                                method: .GET,
                                headers: [:],
                                code: 200,
                                elapsed: 0.07251596450805664,
                                time: Date(),
                                body: nil,
                                response: nil, error: nil), to: .images)
        return manager
    }
}

#Preview {
    SentryView(manager: SentryView.preview)
}


// MARK: - Sentry Detail ---------------------------------------------------------------------------------------------


fileprivate struct SentryDetailView: View {
    
    let entry: SentryEntry
    @Environment(\.dismiss) private var dismiss
    @State private var isPortrait = true
    
    var body: some View {
        
        GeometryReader { geo in
            Group {
                if isPortrait {
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
                        .navigationTitle(entry.endPoint.capitalized)
                        .toolbar(removing: .sidebarToggle)
                        .toolbar {
                            curlToolbar
                            closeToolbar
                        }
                    }
                } else { // Landscape
                    NavigationStack {
                        NavigationSplitView {
                            List {
                                requestSection.padding(.top, 10)
                                urlSection
                                headersSection
                                bodySection
                            }
                            .scrollIndicators(.hidden)
                            .listStyle(.insetGrouped)
                            .toolbar(removing: .sidebarToggle)
                        } detail: {
                            List {
                                responseSection
                            }
                            .scrollIndicators(.hidden)
                            .listStyle(.insetGrouped)
                            .toolbar(.hidden)
                            .toolbar(removing: .sidebarToggle)
                            .contentMargins(.top, 0, for: .scrollContent)
                        }
                        .toolbar(removing: .sidebarToggle)
                        .navigationTitle(entry.endPoint.capitalized)
                        .toolbar {
                            curlToolbar
                            closeToolbar
                        }
                    }
                }
            }
            .onAppear { isPortrait = geo.size.height > geo.size.width }
            .onChange(of: geo.size) { _, newSize in isPortrait = newSize.height > newSize.width }
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    var curlToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                UIPasteboard.general.string = entry.curlString
                Toaster.shared.show(String(localized: "copiedClipboard"))
            } label: {
                Image(systemName: "curlybraces")
                    .font(.system(size: 15))
            }
        }
    }
    
    @ToolbarContentBuilder
    var closeToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15))
            }
        }
    }
    
    // MARK: - Request
    var requestSection: some View {
        
        let copyText = "[\(entry.method)] \(entry.endPoint.capitalized) (code: \(entry.code))"
        let hasError = entry.error != nil
        
        return Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack {
                        TextChip(title: entry.method.rawValue)
                        Text(entry.endPoint.capitalized)
                            .font(.caption)
                            .lineLimit(nil)
                            .padding(.vertical, 4)
                    }
                    Spacer()
                    Text(entry.isCache ? String(localized: "cached") : String(entry.code))
                        .foregroundColor(entry.isCache ? .green : entry.code.color())
                        .font(.subheadline.bold())
                }
                .padding(.vertical, 4)
                
                if let error = entry.error {
                    Divider()
                    VStack(alignment: .leading, spacing: 2) {
                        TextChip(title: error.type.rawValue.capitalized, color: .red)
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
                    .font(.caption.bold())
                Spacer()
                Text("\(Int(entry.elapsed * 1000)) ms")
                    .font(.caption2)
            }
        }
        .if(hasError) {
            $0.copyable(title: String(localized: "error"),
                        text: "[\(entry.error!.type.rawValue.capitalized)] \(entry.error!.localize())",
                        color: .red,
                        icon: "exclamationmark.square.fill")
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
                    .font(.caption.bold())
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
                        .font(.caption.bold())
                    if hasAuth {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                    }
                    Spacer()
                    Text("\(headers.count) header\(headers.count > 1 ? "s" : "")")
                        .font(.caption2)
                }
            }
                .if(hasAuth) {
                    $0.copyable(title: String(localized: "token"),
                                text: headers[APIHeader.authorization] ?? "",
                                color: .orange,
                                icon: "lock.rectangle.on.rectangle.fill")
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
                        .font(.caption.bold())
                    Spacer()
                    Text("\(body.count) bytes")
                        .font(.caption2)
                }
            }.copyable(text: entry.body.prettyPrint().truncated(500))
        )
    }
    
    
    // MARK: - Response
    var responseSection: some View {
        
        let responseHeader = {
            HStack {
                Text("response")
                    .font(.caption.bold())
                Spacer()
                Text("\(entry.response?.count ?? 0) bytes")
                    .font(.caption2)
            }
        }
        
        return AnyView(
            Section {
                VStack(spacing: 20) {
                    if !isPortrait {
                        responseHeader()
                            .padding(.horizontal, 10)
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.response.prettyPrint().truncated(4000))
                        .font(.caption)
                        .lineLimit(nil)
                }
            } header: {
                if isPortrait { responseHeader() }
            }.copyable(text: entry.response.prettyPrint().truncated(4000))
        )
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
    private let spacing: CGFloat = 6
    
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
        FlexibleView(items: items, spacing: spacing) { item in
            HStack(spacing: spacing) {
                Text(item.key)
                Text(item.value)
                    .foregroundColor(item.value == "__" ? .red : .secondary)
            }
            .lineLimit(1)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, spacing)
            .padding(.vertical, 6)
            .background(.gray.opacity(0.2))
            .cornerRadius(6)
        }
    }
}


// MARK: - Flexible View
fileprivate struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Identifiable {
    
    let items: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    @State private var maxWidth: CGFloat = 0
    
    var body: some View {
        generateContent(in: maxWidth)
            .background(GeometryReader { geo in
                Color.clear
                    .onAppear { maxWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, newWidth in maxWidth = newWidth }
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
        let text = (item as? ChipItem).map { $0.key + $0.value } ?? ""
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10, weight: .medium)] // Same font as ChipItem
        return text.size(withAttributes: attributes).width + (spacing * 2)
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
        .navigationViewStyle(.stack)
    }
}

// MARK: - Extensions
fileprivate extension SentryEntry {
    var curlString: String {
        var components = ["curl"]
        
        if method != .GET {
            components.append("-X \(method.rawValue)")
        }
        
        headers.forEach { key, value in
            components.append("-H \"\(key): \(value)\"")
        }
        
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            let escaped = bodyString.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-d \"\(escaped)\"")
        }
        
        components.append("\"\(url)\"")
        
        return components.joined(separator: " \\\n  ")
    }
}

// MARK: - TextChip
fileprivate struct TextChip: View {
    let title: String
    var color: Color = .gray
    
    var body: some View {
        Text(String(localized: String.LocalizationValue(title)))
            .font(.caption.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .if(color != .gray) { $0.foregroundStyle(color) }
            .cornerRadius(6)
    }
}

