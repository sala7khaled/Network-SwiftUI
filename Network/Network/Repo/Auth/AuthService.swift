//
//  AuthService.swift
//  Network
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation

enum AuthService: ServiceProtocol {
    
    case getUsers(_ request: BreedModel)
    case createUser
    
    
    var url: String { API.baseUrl }
    
    
    var path: String {
        switch self {
        case .getUsers:
            return API.AUTH_BREEDS
        case .createUser:
            return API.AUTH_BREEDS
        }
    }
    
    
    var method: HTTPMethod {
        switch self {
        case .getUsers:
            return .GET
        case .createUser:
            return .GET
        }
    }
    
    
    var parameters: Parameters? {
        return ["ssss": "sadadad:ssss",
                "dada": "fgaadadaqq"]
    }
    
    
    var headers: Headers? { nil }
    
    
    var body: Encodable? {
        return nil
        switch self {
        case .getUsers(let request):
            return request
        case .createUser:
            return nil
        }
    }
    
    
    var responseType: Decodable.Type {
        switch self {
        case .getUsers:
            return BaseResponse<[BreedModel]>.self
        default:
            return EmptyResponse.self
        }
    }
}
