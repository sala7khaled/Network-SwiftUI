//
//  Console.swift
//  Network
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation

open class Console {
    
    static private var separator = String(repeating: "—", count: 124)
    
    static func log(_ request: URLRequest,
                    _ service: ServiceProtocol,
                    _ responseData: Data?,
                    _ statusCode: Int) {
        
        let url = request.url?.absoluteString ?? (service.url + service.path)
        let headers = (request.allHTTPHeaderFields ?? [:]).prettyPrint()
        let body = request.httpBody.prettyPrint().truncated(500)
        let response = responseData.prettyPrint().truncated(3000)
        
        print("\n" + separator)
        log("🌐 Url", url)
        log("🧩 Headers", "\n\(headers)")
        log("📦 Body", body == "" ? "{ }" : "\n\(body)")
        log("#️⃣ Status code", statusCode)
        log("📂 Response", "\n\(response)")
        
        let endPoint = url.replacingOccurrences(of: API.baseUrl, with: "")
        switch statusCode {
        case 200...299:
            log("🏁 \(endPoint)", "✅ Success")
            break
        default:
            log("🚩 \(endPoint)", "❌ Failed")
            break
        }
        print(separator)
    }
    
    static func logError(_ request: URLRequest, _ error: APIError) {
        let url = request.url?.absoluteString ?? "Error"
        let endPoint = url.replacingOccurrences(of: API.baseUrl, with: "")
        
        print("\n" + separator)
        log("❌ \(endPoint)", "\(error.type)".capitalized + " error (code: \(error.code ?? 0)) \n   \(error.message ?? "")")
        print(separator)
    }
    
    static func log(_ tag: String, _ text: Any) {
        #if DEBUG
        print("\(tag): \(text)")
        #endif
    }
}
