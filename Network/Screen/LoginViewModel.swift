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
    private let authRepo = AuthRepo()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load Users
    func fetchUsers() {
        
        isLoading = true
        errorMessage = nil
        
//        network.call(service: AuthService.getUsers,
//                     type: BaseResponse<[BreedModel]>.self)
        
        authRepo.getUsers()
        .sink { completion in
            switch completion {
            case .finished:
                self.isLoading = false
                break
            case .failure(let error):
                self.errorMessage = error.errorDescription
            }
        } receiveValue: { response in
            self.breeds = response.data ?? []
        }
        .store(in: &cancellables)
    }
}
