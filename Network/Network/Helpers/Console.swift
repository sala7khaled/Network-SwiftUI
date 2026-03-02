//
//  Console.swift
//  Network
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation

open class Console {
    
    static func log(_ request: URLRequest, _ service: ServiceProtocol, _ body: Data?, _ data: Data?, _ response: URLResponse?) {
        
        let httpResponse = response as? HTTPURLResponse
        let urlString = request.url?.absoluteString ?? service.url + service.path
        let headers = (request.allHTTPHeaderFields ?? [:]).prettyPrint()
        let statusCode = httpResponse?.statusCode ?? 0
        
        let requestBody = body.prettyPrint()
        let responseBody = data.prettyPrint()
        
        info(urlString, headers, requestBody, statusCode, responseBody, nil)
    }
    
    private static func info(_ url: String, _ headers: String, _ body: String, _ statusCode: Int, _ response: String, _ error: Error?) {
        l("\n🔽 ---------------------------- API Calling Started", "---------------------------- 🔽")
        l("🌐 Url", url)
        l("🧩 Headers", "\n\(headers)")
        l("📦 Body", body == "" ? "{ }" : body)
        l("#️⃣ Status code", statusCode)
        l("📂 Response", "\n\(response)")
        
        let endPoint = url.replacingOccurrences(of: API.baseUrl, with: "")
        switch statusCode {
        case 200...299:
            l("🏁 \(endPoint)", "✅ Success")
            break
        default:
            l("🚩 \(endPoint)", "❌ Error: \(String(describing: error))")
            break
        }
        l("🔼 ---------------------------- API Calling Ended", "---------------------------- 🔼\n")
    }
    
    private static func l(_ tag: String, _ text: Any) {
        #if DEBUG
        print("\(tag): \(text)")
        #endif
    }
}


// MARK: - Pretty Print
extension Data? {
    func prettyPrint() -> String {
        guard let data = self else { return "{ }" }
        
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: object,
                                                        options: [.prettyPrinted, .sortedKeys])
            return String(decoding: prettyData, as: UTF8.self)
        } catch {
            return String(decoding: data, as: UTF8.self)
        }
    }
}


extension Headers {
    func prettyPrint() -> String {
        
        guard !self.isEmpty else { return "[ ]" }
        let sorted = self.sorted { $0.key.lowercased() < $1.key.lowercased() }
        let maxLength = sorted.map { $0.key.count }.max() ?? 0
        
        return sorted.map { key, value in
            let paddedKey = key.padding(toLength: maxLength, withPad: " ", startingAt: 0)
            return "   [\(paddedKey)]  \(value)"
        }
        .joined(separator: "\n")
    }
}
