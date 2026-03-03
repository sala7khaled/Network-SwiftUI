//
//  Console.swift
//  Network
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation

open class Console {
    
    static func log(_ request: URLRequest,
                    _ service: ServiceProtocol,
                    _ responseData: Data?,
                    _ statusCode: Int) {
        
        let url = request.url?.absoluteString ?? (service.url + service.path)
        let headers = (request.allHTTPHeaderFields ?? [:]).prettyPrint()
        let body = request.httpBody.prettyPrint()
        let response = responseData.prettyPrint().truncated(3000)
        
        log("\n🔽 ---------------------------- API Calling Started", "---------------------------- 🔽")
        log("🌐 Url", url)
        log("🧩 Headers", "\n\(headers)")
        log("📦 Body", body == "" ? "{ }" : body)
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
        log("🔼 ---------------------------- API Calling Ended", "---------------------------- 🔼\n")
    }
    
    static func logError(_ error: Error?, _ request: URLRequest, _ service: ServiceProtocol) {
        let url = request.url?.absoluteString ?? (service.url + service.path)
        let endPoint = url.replacingOccurrences(of: API.baseUrl, with: "")
        log("🚩 \(endPoint)", "❌ Error: \(error?.localizedDescription ?? "nil")")
    }
    
    private static func log(_ tag: String, _ text: Any) {
        #if DEBUG
        print("\(tag): \(text)")
        #endif
    }
}


// MARK: - Data Pretty Print
extension Data? {
    
    func prettyPrint(max: Int = 80) -> String {
        guard let data = self else { return "{ }" }
        
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: [])
            let truncatedObject = truncate(object, max: max)
            
            let prettyData = try JSONSerialization.data(withJSONObject: truncatedObject,
                                                        options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            
            return String(decoding: prettyData, as: UTF8.self)
        } catch {
            return String(decoding: data, as: UTF8.self)
        }
    }
    
    // MARK: - Truncation
    private func truncate(_ value: Any, max: Int) -> Any {
        
        switch value {
        case let dict as [String: Any]:
            return dict.mapValues { truncate($0, max: max) }
            
        case let array as [Any]:
            return array.map { truncate($0, max: max) }
            
        case let string as String:
            if string.count > max {
                let visible = String(string.prefix(max))
                let remain = string.count - max
                return "\(visible)... + (\(remain) chars)"
            }
            return string
        default:
            return value
        }
    }
}

// MARK: - Header Pretty Print
extension Headers {
    func prettyPrint() -> String {
        
        guard !self.isEmpty else { return "[ ]" }
        let sorted = self.sorted { $0.key.lowercased() < $1.key.lowercased() }
        let maxLength = sorted.map { $0.key.count }.max() ?? 0
        
        return sorted.map { key, value in
            let paddedKey = key.padding(toLength: maxLength, withPad: " ", startingAt: 0)
            let key = paddedKey.contains(APIHeader.authorization) ? "🔐 " : ""
            return "   [\(paddedKey)]  \(key)\(value)"
        }
        .joined(separator: "\n")
    }
}

// MARK: - String
extension String {
    func truncated(_ max: Int) -> String {
        guard count > max else { return self }
        
        let visible = prefix(max)
        let remain = count - max
        return "\(visible)... + (\(remain) chars)"
    }
}
