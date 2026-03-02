//
//  Network.swift
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
    
    // MARK: - Request
    func call<T: Decodable>(_ service: ServiceProtocol, responseType: T.Type) async -> Result<T, APIError> {
        do {
            let result = try await request(service, responseType: responseType)
            return .success(result)
        } catch let error as APIError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error))
        }
    }
    
    private func request<T: Decodable>(_ service: ServiceProtocol, responseType: T.Type) async throws -> T {
        
        let policy = urlCachePolicy(service.method == .GET)
        guard let request = URLRequest(service: service, cachePolicy: policy, timeoutInterval: requestTime) else {
            throw APIError.url
        }
        
        let (data, response) = try await session.data(for: request)
        
        #if DEBUG
        Console.log(request, service, request.httpBody, data, response)
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.request
        }
        
        return try handleResponse(data: data, response: httpResponse)
    }
}

// MARK: - Extensions
private extension Network {
    
    func handleResponse<T: Decodable>(data: Data?, response: HTTPURLResponse) throws -> T {
        guard let apiData = data else { throw APIError.request }
        
        switch response.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: apiData)
            } catch {
                throw APIError.parsing
            }
            
        case 401:
            throw APIError.unauthorized
            
        default:
            guard let fail = try? JSONDecoder().decode(Fail.self, from: apiData) else {
                throw APIError.server(response.statusCode)
            }
            
            throw APIError.backend(fail)
        }
    }
    
    // MARK: - Cache Policy
    private func urlCachePolicy(_ isCache: Bool) -> URLRequest.CachePolicy {
        online = ReachabilityManager.isOnline()
        
        return isCache
        ? (online ? .reloadIgnoringCacheData : .returnCacheDataDontLoad)
        : .reloadIgnoringCacheData
    }
}
