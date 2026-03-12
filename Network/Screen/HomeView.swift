//
//  HomeView.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            productView
                .navigationTitle(String(localized: "users"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(viewModel.products.count) / \(viewModel.totalProducts)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(minWidth: 60)
                    }
                }
                .task { viewModel.fetchProducts() }
        }
    }
    
    // MARK: - Product View
    @ViewBuilder
    private var productView: some View {
        
        /// Loading
        if viewModel.isLoading && viewModel.products.isEmpty {
            ProgressView(String(localized: "loading"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        /// Error
        else if let error = viewModel.error, viewModel.products.isEmpty {
            VStack(spacing: 12) {
                
                Text(error.localize())
                    .foregroundColor(.red)
                
                Button(String(localized: "retry")) {
                    Task { viewModel.fetchProducts() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        /// Success
        else {
            VStack {
                List(viewModel.products) { product in
                    VStack(alignment: .leading) {
                        
                        Text(product.title ?? "")
                            .font(.headline)
                        
                        if let description = product.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(3)
                        }
                    }
                    .onAppear {
                        if product.id == viewModel.products.last?.id {
                            viewModel.loadMoreProducts()
                        }
                    }
                }
                .refreshable { viewModel.fetchProducts() }
            }
        }
    }
}

#Preview {
    HomeView()
}
