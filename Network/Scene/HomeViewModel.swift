//
//  HomeViewModel.swift
//  Networking
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published
    @Published var products: [ProductModel] = []
    @Published var totalProducts: Int = 0
    @Published var isLoading = false
    @Published var error: APIError?
    
    
    // MARK: - Properties
    private let homeRepo = HomeRepo()
    private var params = ProductParam(limit: 25, skip: 0, order: "asc", sortBy: "title")
    

    // MARK: - Methods
    func fetchProducts(reset: Bool = true) async {
        
        guard !isLoading else { return }
        
        /// Paginating
        if reset { products.removeAll(); params.skip = 0 }
        error = nil
        isLoading = true
        defer { isLoading = false }
        
        /// Network call
        let result = await homeRepo.fetchProducts(params: params)
        
        switch result {
        case .success(let response):
            guard let products = response.products, !products.isEmpty else {
                params.skip -= params.limit
                return
            }
            self.products += products
            self.totalProducts = response.total ?? 0
            
        case .failure(let error):
            self.error = error
        }
    }
    
    func loadMoreProducts() async {
        guard !isLoading else { return }
        
        params.skip += params.limit
        await fetchProducts(reset: false)
    }
}
