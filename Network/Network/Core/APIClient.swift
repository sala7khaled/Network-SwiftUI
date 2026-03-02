//
//  APIClient.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation
import SystemConfiguration

final class Network {
    
    // MARK: - Properties
    private let session: URLSession
    private let requestTime: TimeInterval = 30.0
    private var online = false
    
    // MARK: - Init
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Cache Policy
    func urlCachePolicy(_ isCache: Bool) -> URLRequest.CachePolicy {
        online = ReachabilityManager.isOnline()
        return isCache
        ? (online ? .reloadIgnoringCacheData : .returnCacheDataDontLoad)
        : .reloadIgnoringCacheData
    }
    
    // MARK: - Request
    @MainActor
    func call<T: Decodable>(_ service: ServiceProtocol, responseType: T.Type) async -> Result<T, APIError> {
        
        do {
            let result = try await request(service, responseType: responseType)
            return .success(result)
            
        } catch let error as APIError {
            return .failure(error)
            
        } catch {
            return .failure(APIError.unknown(error))
        }
    }
    
    private func request<T: Decodable>(
        _ service: ServiceProtocol,
        responseType: T.Type
    ) async throws -> T {
        
        guard let request = URLRequest(
            service: service,
            cachePolicy: urlCachePolicy(service.method == .GET),
            timeoutInterval: requestTime
        ) else {
            throw APIError.url
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            
            #if DEBUG
            self.info(request, service, request.httpBody, data, response)
            #endif
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.request
            }
            
            return try handleResponse(data: data,response: httpResponse)
            
        } catch let error as APIError {
            throw error
        } catch {
            online = ReachabilityManager.isOnline()
            throw online ? APIError.unknown(error) : APIError.network
        }
    }
}

// MARK: - Extensions
private extension Network {
    
    func handleResponse<T: Decodable>(data: Data?, response: HTTPURLResponse) throws -> T {
        
        guard let apiData = data else {
            throw APIError.request
        }
        
        switch response.statusCode {
            
        case 200...299:
            
            do {
                return try JSONDecoder().decode(T.self, from: apiData)
            } catch {
                throw APIError.parsing
            }
            
        case 401:
            
            // Session expired
            throw APIError.server(response.statusCode)
            
        default:
            
            // Try decode backend error body
            if let fail = try? JSONDecoder().decode(Fail.self, from: apiData) {
                print(fail.message ?? "Something went worng")
            }
            
            throw APIError.server(response.statusCode)
        }
    }
    
    // MARK: - General Function To Log API Info
//    func info(_ task: URLSessionDataTask, _ body: Any?, _ data: Data?, _ response: URLResponse?, _ error: Error?) {
//        let url: String = task.originalRequest?.url?.absoluteString ?? ""
//        let headers: [String: String] = task.originalRequest?.allHTTPHeaderFields ?? [:]
//        let statusCode: Int = (task.response as? HTTPURLResponse)?.statusCode ?? 0
//        let body: String = String(data: (body as? Data) ?? Data(), encoding: .utf8) ?? ""
//        let response: String = String(data: data ?? Data(), encoding: .utf8) ?? ""
//        Console.logAPI(url, headers, body, statusCode, response, error)
//    }
    
    // MARK: - General Function To Log API Info
    private func info(_ request: URLRequest, _ service: ServiceProtocol, _ body: Data?, _ data: Data?, _ response: URLResponse?) {
        
        let httpResponse = response as? HTTPURLResponse
        let urlString = request.url?.absoluteString ?? API.baseUrl + service.path
        let headers = prettyPrintedHeaders(request.allHTTPHeaderFields ?? [:])
        let statusCode = httpResponse?.statusCode ?? 0
        
        let requestBody = prettyPrint(from: body)
        let responseBody = prettyPrint(from: data)
        
        Console.logAPI(urlString, headers, requestBody, statusCode, responseBody, nil)
    }
}

private func prettyPrintedHeaders(_ headers: [String: String]) -> String {
    
    guard !headers.isEmpty else { return "[ ]" }
    let sorted = headers.sorted { $0.key.lowercased() < $1.key.lowercased() }
    let maxLength = sorted.map { $0.key.count }.max() ?? 0
    
    return sorted.map { key, value in
        let paddedKey = key.padding(toLength: maxLength, withPad: " ", startingAt: 0)
        return "   [\(paddedKey)]  \(value)"
    }
    .joined(separator: "\n")
}


 func prettyPrint(from data: Data?) -> String {
    guard let data = data else { return "{ }" }
    
    do {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(withJSONObject: object,
                                                    options: [.prettyPrinted, .sortedKeys])
        return String(decoding: prettyData, as: UTF8.self)
    } catch {
        return String(decoding: data, as: UTF8.self)
    }
}


open class Console {
    
    static func logAPI(_ url: String, _ headers: String, _ body: String, _ statusCode: Int, _ response: String, _ error: Error?) {
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
            log("🚩 \(endPoint)", "❌ Error: \(String(describing: error))")
            break
        }
        log("🔼 ---------------------------- API Calling Ended", "---------------------------- 🔼\n")
    }
    
    static func log(_ tag: String, _ text: Any) {
        #if DEBUG
        print("\(tag): \(text)")
        #endif
    }
}
