//
//  API.swift
//  Networking
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation

/**
 APIConfiguration
 
 - parameter development: For the application during the development phase.
 - parameter production: For the application during the launching on App store.
 */

let API = Api(config: .development)

enum APIConfiguration {
    case development
    case production
}

final class Api {
    
    let config: APIConfiguration
    
    init(config: APIConfiguration) {
        self.config = config
    }
    
    // MARK: - Base Url
    var baseUrl: String {
        switch config {
        case .development:
            return "https://dummyjson.com/"
        case .production:
            return "https://dummyjson.com/"
        }
    }
     
    // MARK: - Home
    let products = "products"
    let addProducts = "products/add"
}
