//
//  NetworkImageLoader.swift
//  Networking
//
//  Created by Salah Khaled on 12/03/2026.
//

import SwiftUI
import Combine

// MARK: - Network Image
final class NetworkImage: ObservableObject {
    
    // MARK: - Properties
    static let shared = NetworkImage()
    private var runningRequests = [UUID: AnyCancellable]()
    @Published private(set) var cache = [URL: UIImage]()
    
    // MARK: - Methods
    func loadImage(_ url: URL) -> AnyPublisher<UIImage?, Never> {
        
        if let image = cache[url] {
            return Just(image).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .catch { _ in Just(nil) }
            .handleEvents(receiveOutput: { [weak self] image in
                if let image = image {
                    self?.cache[url] = image
                }
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func cancel(_ uuid: UUID) {
        runningRequests[uuid]?.cancel()
        runningRequests.removeValue(forKey: uuid)
    }
    
    func track(_ uuid: UUID, cancellable: AnyCancellable) {
        runningRequests[uuid] = cancellable
    }
}

// MARK: - Image View
struct ImageView: View {
    
    // MARK: - State
    @State private var image: UIImage? = nil
    @State private var requestId: UUID? = nil
    @State private var isLoading: Bool = true
    
    // MARK: - Properties
    let urlString: String?
    let loadingView: AnyView
    let holderView: AnyView
    
    // MARK: - Private
    private let defaultHolder = AnyView(Image(systemName: "photo.badge.exclamationmark.fill"))
    private let defaultLoading = AnyView(ProgressView())
    
    // MARK: - Init
    init(_ url: String?, loading: AnyView? = nil, placeholder: AnyView? = nil) {
        self.urlString = url
        self.loadingView = loading ?? defaultLoading
        self.holderView = placeholder ?? defaultHolder
    }
    
    // MARK: - View
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
              loadingView
            } else {
                holderView
                    .symbolRenderingMode(.multicolor)
                    .opacity(0.5)
            }
        }
        .onAppear { load() }
        .onDisappear { cancel() }
    }
    
    // MARK: - Methods
    private func load() {

        if let uuid = requestId {
            NetworkImage.shared.cancel(uuid)
        }
        
        image = nil
        isLoading = true
        
        guard let urlString = urlString, let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        let uuid = UUID()
        requestId = uuid
        
        let cancellable = NetworkImage.shared.loadImage(url)
            .sink { loadedImage in
                if requestId == uuid {
                    image = loadedImage
                    isLoading = false
                }
            }
        
        NetworkImage.shared.track(uuid, cancellable: cancellable)
    }
    
    private func cancel() {
        if let uuid = requestId {
            NetworkImage.shared.cancel(uuid)
        }
    }
}
