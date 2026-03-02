//
//  Network.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import Foundation
import SystemConfiguration
import Combine


// MARK: - Protocol
protocol NetworkProtocol {
    func call<T: Decodable>(service: ServiceProtocol, type: T.Type) -> AnyPublisher<T, APIError>
}


// MARK: - Network
final class Network: NetworkProtocol {
    
    // MARK: - Properties
    private let session: URLSession
    private let requestTime: TimeInterval = 30.0
    private var online = false
    
    // MARK: - Init
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Call
    func call<T: Decodable>(service: ServiceProtocol, type: T.Type) -> AnyPublisher<T, APIError> {
        
        let policy = urlCachePolicy(service.method == .GET)
        guard let request = URLRequest(service: service, cachePolicy: policy, timeoutInterval: requestTime) else {
            return Combine.Fail<T, APIError>(error: APIError.url)
                .eraseToAnyPublisher()
        }
        
        return session
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap { data, response -> T in
                
                guard let response = response as? HTTPURLResponse else { throw APIError.request }
                
                #if DEBUG
                Console.log(request, service, data, response.statusCode)
                #endif
                
                return try self.handle(response: response, data: data)
            }
            .mapError { error -> APIError in
                
                #if DEBUG
                Console.logError(error, request, service)
                #endif
                
                if let apiError = error as? APIError { return apiError }
                return .unknown(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    // MARK: - Handle
    private func handle<T: Decodable>(response: HTTPURLResponse, data: Data?) throws -> T {
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
}

// MARK: - Extensions
private extension Network {
    private func urlCachePolicy(_ isCache: Bool) -> URLRequest.CachePolicy {
        online = ReachabilityManager.isOnline()
        
        return isCache
        ? (online ? .reloadIgnoringCacheData : .returnCacheDataDontLoad)
        : .reloadIgnoringCacheData
    }
}
