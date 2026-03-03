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
        
        guard let request = URLRequest(service: service,
                                       cachePolicy: cachePolicy(service.method == .GET),
                                       timeoutInterval: requestTime) else {
            
            return Fail<T, APIError>(error: APIError(type: .url)).eraseToAnyPublisher()
        }
        
        return session
            .dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global(qos: .background))
            .tryMap { data, response -> T in
                guard let response = response as? HTTPURLResponse else { throw APIError(type: .request) }
                
                /// Success
                Console.log(service: service, request: request, data: data, code: response.statusCode)
                return try self.handle(response: response, data: data)
            }
            .mapError { error -> APIError in
                
                /// Error
                let apiError = (error as? APIError) ?? APIError(type: .unknown, message: error.localizedDescription)
//                Console.log(service: service, request: request, data: nil, code: apiError.code, error: apiError)
                return apiError
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Handle
    private func handle<T: Decodable>(response: HTTPURLResponse, data: Data?) throws -> T {
        
        guard online else { throw APIError(type: .network) }
        guard let apiData = data else { throw APIError(type: .request, code: response.statusCode) }
        
        switch response.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: apiData)
            } catch let decodeError as DecodingError {
                throw APIError(type: .parsing, code: response.statusCode, message: decodeError.errorPath)
            } catch {
                throw APIError(type: .parsing, code: response.statusCode)
            }
            
        case 401:
            throw APIError(type: .unauthorized, code: response.statusCode)
            
        default:
            guard let failResponse = try? JSONDecoder().decode(FailResponse.self, from: apiData) else {
                throw APIError(type: .server, code: response.statusCode)
            }
            
            throw APIError(type: .backend, code: failResponse.code ?? response.statusCode, message: failResponse.message)
        }
    }
}

// MARK: - Extensions
private extension Network {
    private func cachePolicy(_ isCache: Bool) -> URLRequest.CachePolicy {
        online = Connectivity.isOnline()
        
        return isCache
        ? (online ? .reloadIgnoringCacheData : .returnCacheDataDontLoad)
        : .reloadIgnoringCacheData
    }
}

