//
//  Service.swift
//  Networking
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation

enum AuthService: ServiceProtocol {
    
    case getUsers
    case createUser
    
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
    
    var headers: Headers? {
        switch self {
        case .getUsers, .createUser:
            return nil
        }
    }
    
    var parameters: Parameters? {
        nil
    }
    
    var body: Encodable? {
        switch self {
        case .getUsers:
            return nil
        case .createUser:
            return nil
        }
    }
    
    var response: Decodable? {
        switch self {
        case .getUsers:
            return BaseResponse<[BreedModel]>.self
        case .createUser:
            return nil
        }
    }
}
