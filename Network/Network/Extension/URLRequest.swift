//
//  File.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import UIKit

extension URLRequest {
    
    init?(service: ServiceProtocol, cachePolicy: CachePolicy, timeoutInterval: TimeInterval) {
        guard let components = URLComponents(service: service),
              let url = components.url else { return nil }
        
        self.init(url: url,
                  cachePolicy: cachePolicy,
                  timeoutInterval: timeoutInterval)
        
        httpMethod = service.method.rawValue
        
        // MARK: Default Headers
        
        addValue("application/json", forHTTPHeaderField: APIHeader.contentType)
        addValue("application/json", forHTTPHeaderField: APIHeader.accept)
        addValue("iOS", forHTTPHeaderField: APIHeader.platform)
        //        addValue(Localization.shared.currentLanguage().identifier, forHTTPHeaderField: APIHeader.locale)
        
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            addValue(uuid, forHTTPHeaderField: APIHeader.deviceId)
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            addValue(version, forHTTPHeaderField: APIHeader.version)
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            addValue(build, forHTTPHeaderField: APIHeader.build)
        }
        
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            addValue("Bearer \(token)", forHTTPHeaderField: APIHeader.authorization)
        }
        
        // MARK: Set Headers
        service.headers?.forEach {
            addValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        // MARK: Body Encoding (Safe)
        if let body = service.body {
            httpBody = try? JSONEncoder().encode(AnyEncodable(body))
        }
    }
}
