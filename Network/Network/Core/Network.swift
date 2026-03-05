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
    private let requestTime: TimeInterval = 30
    private let decoder = JSONDecoder()
    
    // MARK: - Init
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Call
    func call<T: Decodable>(service: ServiceProtocol, type: T.Type) -> AnyPublisher<T, APIError> {
        
        guard let request = URLRequest(service: service,
                                       cachePolicy: cachePolicy(service.method == .GET),
                                       timeoutInterval: requestTime) else {
            return Fail<T, APIError>(error: APIError(type: .url)).eraseToAnyPublisher()
        }
        
        let startTime = Date()
        return session
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap { data, response -> T in
                guard let response = response as? HTTPURLResponse else { throw APIError(type: .request) }
                
                /// Success
                let elapsed = Date().timeIntervalSince(startTime)
                Console.log(service: service, request: request, data: data, code: response.statusCode, time: elapsed)
                return try self.handle(response: response, with: data)
                
            }
            .mapError { error -> APIError in
                
                /// Error
                let apiError = (error as? APIError) ?? APIError(type: .unknown, message: error.localizedDescription)
                if apiError.type == .unknown {
                    Console.log(service: service, request: request, data: nil, code: apiError.code, error: apiError)
                }
                return apiError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Handle
    private func handle<T: Decodable>(response: HTTPURLResponse, with data: Data?) throws -> T {
        
        guard Connectivity.isOnline() else { throw APIError(type: .network) }
        guard let apiData = data else { throw APIError(type: .request, code: response.statusCode) }
        
        switch response.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: apiData)
            } catch let decodeError as DecodingError {
                throw APIError(type: .parsing, code: response.statusCode, message: decodeError.errorPath)
            } catch {
                throw APIError(type: .parsing, code: response.statusCode)
            }
            
        case 401:
            throw APIError(type: .unauthorized, code: response.statusCode)
            
        default:
            guard let failResponse = try? decoder.decode(FailResponse.self, from: apiData) else {
                throw APIError(type: .server, code: response.statusCode)
            }
            
            throw APIError(type: .backend, code: failResponse.code ?? response.statusCode, message: failResponse.message)
        }
    }
}

// MARK: - Extensions
private extension Network {
    private func cachePolicy(_ isCache: Bool) -> URLRequest.CachePolicy {
        return isCache
        ? (Connectivity.isOnline() ? .reloadIgnoringCacheData : .returnCacheDataDontLoad)
        : .reloadIgnoringCacheData
    }
}

