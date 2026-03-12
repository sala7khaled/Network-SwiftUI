//
//  HomeViewModel.swift
//  Network
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation
import SwiftUI
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
    private var cancellables = Set<AnyCancellable>()
    
    private var params = ProductParam(limit: 10, skip: 0)
    private var isPaginating = false
    
    
    // MARK: - Private
    private func startLoading(reset: Bool) {
        if reset {
            products = []
            params.skip = 0
        }
        isLoading = true
        error = nil
    }
    
    private func checkEmptyProducts(_ products: [ProductModel]) {
        guard products.isEmpty else { return }
        params.skip -= params.limit
    }
    
    
    // MARK: - Methods
    func fetchProducts(reset: Bool = true) {
        guard !isPaginating else { return }
        
        startLoading(reset: reset)
        isPaginating = !reset
        
        homeRepo.getProducts(params: params)
            .sink { completion in
                self.isLoading = false
                self.isPaginating = false
                
                if case .failure(let error) = completion {
                    self.error = error
                }
            } receiveValue: { response in
                if reset { self.products = [] }
                
                let newProducts = response.products ?? []
                self.products += newProducts
                
                self.checkEmptyProducts(newProducts)
                self.totalProducts = response.total ?? 0
            }
            .store(in: &cancellables)
    }
    
    func loadMoreProducts() {
        params.skip += params.limit
        fetchProducts(reset: false)
    }
}
