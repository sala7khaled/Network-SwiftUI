//
//  API.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation

/**
 APIConfigurations
 
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
    
    var baseUrl: String {
        switch config {
        case .development:
            return "https://dogapi.dog/api/v2/"
        case .production:
            return "https://dogapi.dog/api/v2/"
        }
    }
    
    init(config: APIConfiguration) {
        self.config = config
    }
     
    // MARK: - AUTH
    let AUTH_BREEDS = "breeds"
    /// add more api endpoints
}
