//
//  NetworkImageLoader.swift
//  Networking
//
//  Created by Salah Khaled on 12/03/2026.
//

import SwiftUI
import Combine

// MARK: - Network Image
extension Network {
    func image(_ urlString: String) async -> UIImage? {
        
        guard let url = URL(string: urlString) else { return nil }
        guard imageCache[url] == nil else { return imageCache[url] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                imageCache[url] = image
                return image
            }
        } catch {
            return nil
        }
        return nil
    }
}

// MARK: - Image View
struct ImageView: View {
    
    // MARK: - State
    @State private var image: UIImage?
    @State private var isLoading = true
    
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
        .task(id: urlString) {
            await load()
        }
    }
    
    // MARK: - Load
    @MainActor
    private func load() async {
        image = nil
        isLoading = true
        
        guard let urlString else {
            isLoading = false
            return
        }
        
        let loadedImage = await Network.shared.image(urlString)
        image = loadedImage
        isLoading = false
    }
}
