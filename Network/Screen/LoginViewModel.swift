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
    @Published var error: APIError?
    
    // MARK: - Properties
    private let authRepo = AuthRepo()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load Users
    func fetchUsers() {
        
        breeds = []
        isLoading = true
        error = nil
        
//        network.call(service: AuthService.getUsers,
//                     type: BaseResponse<[BreedModel]>.self)
        
        authRepo.getUsers(breed: BreedModel(id: "1", type: "222", attributes: AttributesModel(name: "1313", description: "!313", life: nil, maleWeight: nil, femaleWeight: nil, hypoallergenic: true)))
        .sink { completion in
            self.isLoading = false
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self.error = error
            }
        } receiveValue: { response in
            self.breeds = response.data ?? []
        }
        .store(in: &cancellables)
    }
}
