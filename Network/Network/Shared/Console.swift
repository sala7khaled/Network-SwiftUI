//
//  Console.swift
//  Networking
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation

open class Console {
    static private var separator = String(repeating: "—", count: 160)
    
    static func log(service: ServiceProtocol,
                    request: URLRequest?,
                    data: Data?,
                    code: Int,
                    elapsed: TimeInterval = 0,
                    error: APIError? = nil,
                    expected: String = "") {
        
        let url = request?.url?.absoluteString ?? (service.url + service.path)
        let headers = (request?.allHTTPHeaderFields ?? [:]).prettyPrint()
        let body = request?.httpBody.prettyPrint().truncated(500)
        let response = data.prettyPrint().truncated(3000)
        let ms = Int(elapsed * 1000).formatted(.number.grouping(.automatic))
        
        print("\n" + separator)
        log("\(Connectivity.shared.isOnline ? "🛜" : "⚠️") \(service.method.rawValue)", url)
        log("🧩 Headers", "\n\(headers)")
        log("📦 Body", body == "" ? "{ }" : "\n\(body ?? "")")
        log("#️⃣ Status code", code)
        log("📂 Response", "\(expected) (\(ms) ms) \n\(response)")
        
        
        let path = url.replacingOccurrences(of: API.baseUrl, with: "")
        let endPoint = path.components(separatedBy: "?").first ?? path

        switch code {
        case 200...299:
            log("🏁 \(endPoint)", "✅ API Success")
            break
        default:
            log("🚩 \(endPoint)", "❌ API Failed")
        }
        print(separator)
        
        if let error {
            log("🚩 \((error.type).rawValue.capitalized) Error", "(code: \(error.code))\n\(error.localize())")
            print(separator)
        }
        
        // MARK: - Sentry
        let entry = SentryEntry(url: url,
                                endPoint: endPoint,
                                method: service.method,
                                headers: request?.allHTTPHeaderFields ?? [:],
                                code: code,
                                elapsed: elapsed,
                                time: Date(),
                                body: request?.httpBody,
                                response: data ?? Data(),
                                error: error,
                                isCache: !Connectivity.shared.isOnline && code == 200)
        
        
        SentryManager.shared.add(entry, to: .requests)
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
    
    // MARK: - Image
    static func logImage(url: URL, data: Data?, error: Error? = nil, elapsed: TimeInterval) {
        let urlString = url.absoluteString
        let endPoint = url.lastPathComponent
        
        let entry = SentryEntry(
            url: urlString,
            endPoint: endPoint,
            method: .GET,
            headers: [:],
            code: error == nil ? 200 : 0,
            elapsed: elapsed,
            time: Date(),
            body: nil,
            response: data,
            error: error as? APIError
        )
        SentryManager.shared.add(entry, to: .images)
    }
}
