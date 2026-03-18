//
//  Generic.swift
//  Network
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation

// MARK: - Empty Response
struct EmptyResponse: Decodable { }


// MARK: - Base Response
struct BaseResponse<T: Decodable>: Decodable {
    let total: Int?
    let skip: Int?
    let limit: Int?
    let products: T?
}


// MARK: - Fail Response
struct FailResponse: Decodable {
    let code: Int?
    let message: String?
}


// MARK: - API Error
struct APIError: Error {
    var type: APIErrorType
    var code: Int = 0
    var message: String?
    
    func localize() -> String {
        String(localized: .init(message ?? type.localized))
    }
}

enum APIErrorType: String {
    case url
    case request
    case network
    case parsing
    case unauthorized
    case server
    case backend
    case unknown
    
    var localized: String {
        "error.\(rawValue)"
    }
}
