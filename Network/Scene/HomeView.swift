//
//  HomeView.swift
//  Networking
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
                .task { await viewModel.fetchProducts() }
                .navigationTitle(String(localized: "products"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(viewModel.products.count) / \(viewModel.totalProducts)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(minWidth: 60)
                    }
                }
        }
        .navigationViewStyle(.stack)
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
                    Task { await viewModel.fetchProducts() }
                }
            }
        }
        
        /// Success
        else {
            List(viewModel.products) { product in
                HStack(alignment: .center, spacing: 16) {
                    
                    ImageView(product.thumbnail)
                        .frame(width: 64, height: 64)
                        .background(.thinMaterial)
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading) {
                        
                        Text(product.title?.capitalized ?? "")
                            .font(.headline)
                            .lineLimit(1)
                        
                        if let description = product.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Text(product.category?.capitalized ?? "")
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                                )
                            Spacer()
                            Text(String(product.price ?? 0))
                                .font(.subheadline.bold())
                                .foregroundColor(.green)
                                .lineLimit(1)
                            
                        }
                    }
                }
                .task {
                    if product.id == viewModel.products.dropLast(4).last?.id {
                        
                        await viewModel.loadMoreProducts()
                        
                    }
                }
            }
            .scrollIndicators(.automatic)
            .refreshable { Task { await viewModel.fetchProducts() } }
        }
    }
}

#Preview {
    HomeView()
}
