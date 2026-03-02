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
struct Fail: Decodable {
    let message: String?
}


// MARK: - API Error
enum APIError: LocalizedError {
    
    case url
    case request
    case network
    case parsing
    case unauthorized
    case server(_ code: Int)
    case backend(Fail)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .url:
            return "Invalid URL link."
        case .request:
            return "Network request failed."
        case .network:
            return "No internet connection."
        case .parsing:
            return "Failed to decode response."
        case .unauthorized:
            return "Session expired, please login again."
        case .server(let code):
            return "Server error with status code: \(code)"
        case .backend(let fail):
            return fail.message
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
