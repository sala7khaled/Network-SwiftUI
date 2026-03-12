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
                .navigationTitle(String(localized: "products"))
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
                    HStack(alignment: .center, spacing: 16) {
                        
                        ImageView(product.thumbnail)
                            .frame(width: 80, height: 80)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading) {
                            
                            Text(product.title?.capitalized ?? "")
                                .font(.headline)
                            
                            if let description = product.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            HStack {
                                Text(product.category?.capitalized ?? "")
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.gray.opacity(0.5), lineWidth: 0.5)
                                    )
                                Spacer()
                                Text(String(product.price ?? 0))
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.green)
                                    .lineLimit(1)
                                
                            }
                        }
                    }
                    .onAppear {
                        if product.id == viewModel.products.last?.id {
                            viewModel.loadMoreProducts()
                        }
                    }
                }
                .scrollIndicators(.automatic)
                .refreshable { viewModel.fetchProducts() }
            }
        }
    }
}

#Preview {
    HomeView()
}
