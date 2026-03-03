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
    let success: Bool?
    let message: String?
    let data: T?
}


// MARK: - Fail
struct FailResponse: Decodable {
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case message = "error"
    }
}


// MARK: - API Error
struct APIError: Error {
    var type: APIErrorType
    var code: Int? = 0
    var message: String?
    
    init(type: APIErrorType, code: Int? = nil, message: String? = nil) {
        self.type = type
        self.code = code
        self.message = message ?? type.localized
    }
    
    func localize() -> String {
        let message = String.LocalizationValue(self.message ?? "")
        var localized = String(localized: message)
        
        if type == .server, let code {
            localized.append(" Status code: \(code)")
        }
        
        return localized
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
