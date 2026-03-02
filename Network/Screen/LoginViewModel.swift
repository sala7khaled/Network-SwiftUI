//
//  LoginViewModel.swift
//  Network
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    
    // MARK: - Published
    @Published var breeds: [BreedModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    private let network: Network
    
    // MARK: - Init
    init(network: Network) {
        self.network = network
    }
    
    // MARK: - Load Users
    func fetchUsers() async {
        
        isLoading = true
        defer { isLoading = false }
        
        let result = await network.call(service: AuthService.getUsers,
                                        type: BaseResponse<[BreedModel]>.self)
        
        switch result {
        case .success(let response):
            breeds = response.data ?? []
            
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }
}
