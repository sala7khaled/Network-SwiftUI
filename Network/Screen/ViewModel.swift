//
//  ViewModel.swift
//  Networking
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ViewModel: ObservableObject {
    
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
        
        let result = await network.call(AuthService.getUsers,
                                        responseType: BaseResponse<[BreedModel]>.self)
        
        isLoading = false
        
        switch result {
        case .success(let response):
            breeds = response.data ?? []
            
        case .failure(let error):
            errorMessage = error
        }
    }
}
