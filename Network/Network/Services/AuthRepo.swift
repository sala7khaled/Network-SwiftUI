//
//  AuthRepo.swift
//  Networking
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation
import Combine

protocol AuthRepoProtocol {
    func getUsers() -> AnyPublisher<BaseResponse<[BreedModel]>, APIError>
}

class AuthRepo: AuthRepoProtocol {
    let network = Network()
    
    func getUsers() -> AnyPublisher<BaseResponse<[BreedModel]>, APIError> {
        return network.call(service: AuthService.getUsers,
                     type: BaseResponse<[BreedModel]>.self)
    }
}
