//
//  URLComponents+Ext.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation

extension URLComponents {
    
    init?(service: ServiceProtocol) {
        guard let baseURL = URL(string: service.url) else { return nil }
        
        let url = baseURL.appendingPathComponent(service.path)
        self.init(url: url, resolvingAgainstBaseURL: false)
        
        if let parameters = service.parameters {
            queryItems = parameters.map {
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
    }
}

