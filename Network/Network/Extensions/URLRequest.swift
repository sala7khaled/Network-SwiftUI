//
//  URLRequest.swift
//  Networking
//
//  Created by Salah Khaled on 28/02/2026.
//

import UIKit

// MARK: - URLRequest
extension URLRequest {
    
    fileprivate enum Key {
        static let appJson = "application/json"
        static let iOS = "iOS"
        static let locale = "en"
        static let version = "CFBundleShortVersionString"
        static let build = "CFBundleVersion"
        static let bearer = "Bearer"
    }
    
    init?(service: ServiceProtocol, cachePolicy: CachePolicy, timeoutInterval: TimeInterval) {
        guard let components = URLComponents(service: service),
              let url = components.url else { return nil }
        
        self.init(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        httpMethod = service.method.rawValue
        
        addValue(Key.appJson, forHTTPHeaderField: APIHeader.contentType)
        addValue(Key.appJson, forHTTPHeaderField: APIHeader.accept)
        addValue(Key.iOS, forHTTPHeaderField: APIHeader.platform)
        addValue(Key.locale, forHTTPHeaderField: APIHeader.locale)
        
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            addValue(uuid, forHTTPHeaderField: APIHeader.deviceId)
        }
        
        if let version = Bundle.main.infoDictionary?[Key.version] as? String {
            addValue(version, forHTTPHeaderField: APIHeader.version)
        }
        
        if let build = Bundle.main.infoDictionary?[Key.build] as? String {
            addValue(build, forHTTPHeaderField: APIHeader.build)
        }
        
        if let token = UserDefaults.standard.string(forKey: APIHeader.authorization) {
            addValue("\(Key.bearer) \(token)", forHTTPHeaderField: APIHeader.authorization)
        }
        
        /// Set Headers
        service.headers?.forEach {
            addValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        /// Body Encoding
        if let body = service.body {
            httpBody = try? JSONEncoder().encode(body)
        }
    }
}


// MARK: - URLComponents
extension URLComponents {
    
    init?(service: ServiceProtocol) {
        guard let baseURL = URL(string: service.url) else { return nil }
        
        let url = baseURL.appendingPathComponent(service.path)
        self.init(url: url, resolvingAgainstBaseURL: false)
        
        if let parameters = service.parameters {
            queryItems = parameters
                .sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }
    }
}
