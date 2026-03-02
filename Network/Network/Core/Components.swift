//
//  Endpoint.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation

// MARK: - Methods
enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

// MARK: - Headers
enum APIHeader {
    static let accept = "Accept"
    static let contentType = "Content-Type"
    static let locale = "Accept-Language"
    static let platform = "Platform"
    static let deviceId = "Device-Id"
    static let version = "Version"
    static let build = "Build"
    static let authorization = "Authorization"
}


// MARK: - Service
typealias Headers = [String: String]
typealias Parameters = [String: Any]

protocol ServiceProtocol {
    
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var headers: Headers? { get }
    var body: Encodable? { get }
    var response: Decodable? { get }
}


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


// MARK: - Response
enum APIResponse<T> {
    
    case onSuccess(T)
    case onFailure(APIError)
}
// MARK: - Error
enum APIError: LocalizedError {
    
    case url
    case request
    case network
    case parsing
    case server(_ code: Int)
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
        case .server(let code):
            return "Server error with status code: \(code)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

//struct APIError {
//    
//    var type: APIErrorType
//    var code: Int? = 0
//    var message: String?
//}
