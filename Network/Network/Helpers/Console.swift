//
//  Console.swift
//  Network
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation

open class Console {
    static private var separator = String(repeating: "—", count: 124)
    
    static func log(service: ServiceProtocol,
                    request: URLRequest?,
                    data: Data?,
                    code: Int,
                    error: APIError? = nil) {
        
        let url = request?.url?.absoluteString ?? (service.url + service.path)
        let headers = (request?.allHTTPHeaderFields ?? [:]).prettyPrint()
        let body = request?.httpBody.prettyPrint().truncated(500)
        let response = data.prettyPrint().truncated(3000)
        
        print("\n" + separator)
        log("🌐 Url", url)
        log("🧩 Headers", "\n\(headers)")
        log("📦 Body", body == "" ? "{ }" : "\n\(body ?? "")")
        log("#️⃣ Status code", code)
        log("📂 Response", "\n\(response)")
        
        
        let endPoint = url.replacingOccurrences(of: API.baseUrl, with: "")
        switch code {
        case 200...299:
            log("🏁 \(endPoint)", "✅ Success")
            break
        default:
            log("❌ Error", "\(error?.type ?? .unknown)".capitalized + " (code: \(code)) \n   \(error?.message ?? "message: nil")")
            break
        }
        print(separator)
    }
    
    static func logError(_ error: APIError) {
        print("\n" + separator)
        log("❌ Error", "\(error.type)".capitalized + " (code: \(error.code)) \n   \(error.message ?? "message: nil")")
        print(separator)
    }
    
    static func log(_ tag: String, _ text: Any) {
        #if DEBUG
        print("\(tag): \(text)")
        #endif
    }
}
