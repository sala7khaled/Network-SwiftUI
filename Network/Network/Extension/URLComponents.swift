//
//  URLComponents+Ext.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation

//extension URLComponents {
//    
//    init(service: ServiceProtocol) {
//        let urlString = API.baseUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//        let baseUrl = URL(string: urlString)
//        let url = baseUrl!.appendingPathComponent(service.path)
//        
//        self.init(url: url, resolvingAgainstBaseURL: false)!
//        
//        /// Set the spasific guery params which assigned by routes
//        guard let parameters = service.parameters else { return }
//        queryItems = parameters.map { key, value in
//            return URLQueryItem(name: key, value: String(describing: value))
//        }
//    }
//}


extension URLComponents {
    
    init?(service: ServiceProtocol) {
        guard let baseURL = URL(string: API.baseUrl) else { return nil }
        
        let url = baseURL.appendingPathComponent(service.path)
        self.init(url: url, resolvingAgainstBaseURL: false)
        
        if let parameters = service.parameters {
            queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
    }
}

