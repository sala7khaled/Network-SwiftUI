//
//  Components.swift
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
    
    var url: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
    var headers: Headers? { get }
    var body: Encodable? { get }
    var responseType: Decodable.Type { get }
}
