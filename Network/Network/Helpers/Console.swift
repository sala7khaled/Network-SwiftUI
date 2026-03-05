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
                    time: TimeInterval = 0,
                    error: APIError? = nil) {
        
        let url = request?.url?.absoluteString ?? (service.url + service.path)
        let headers = (request?.allHTTPHeaderFields ?? [:]).prettyPrint()
        let body = request?.httpBody.prettyPrint().truncated(500)
        let response = data.prettyPrint().truncated(3000)
        
        print("\n" + separator)
        log("🌐 \(request?.httpMethod ?? "")", url)
        log("🧩 Headers", "\n\(headers)")
        log("📦 Body", body == "" ? "{ }" : "\n\(body ?? "")")
        log("#️⃣ Status code", code)
        log("📂 Response", "Expected: \(service.responseType) Time: \(time) \n\(response)")
        
        
        let path = url.replacingOccurrences(of: API.baseUrl, with: "")
        let endPoint = path.components(separatedBy: "?").first ?? path
        switch code {
        case 200...299:
            log("🏁 \(endPoint)", "✅ Success")
            break
        default:
            log("❌ Error", "\(error?.type ?? .unknown)".capitalized + " (code: \(code)) \n   \(error?.message ?? "message: nil")")
            break
        }
        print(separator)
        
        // MARK: - Sentry
        let entry = SentryEntry(url: url, endPoint: endPoint, method: request?.httpMethod ?? "", headers: request?.allHTTPHeaderFields ?? [:], code: code, time: time, response: data ?? Data())
        SentryManager.shared.add(entry)
    }
    
    static func log(_ tag: String, _ text: Any) {
        #if DEBUG
        print("\(tag): \(text)")
        #endif
    }
    
    // MARK: - Error
    static func logError(_ error: APIError) {
        print("\n" + separator)
        log("❌ Error", "\(error.type)".capitalized + " (code: \(error.code)) \n   \(error.message ?? "message: nil")")
        print(separator)
    }
}
