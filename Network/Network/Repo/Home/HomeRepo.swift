//
//  HomeRepo.swift
//  Networking
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation
import Combine

protocol HomeRepoProtocol {
    func getProducts(params: ProductParam) -> AnyPublisher<BaseResponse<[ProductModel]>, APIError>
}

class HomeRepo: HomeRepoProtocol {
    
    func getProducts(params: ProductParam) -> AnyPublisher<BaseResponse<[ProductModel]>, APIError> {
        return Network.shared.call(service: HomeService.getProducts(params), type: BaseResponse<[ProductModel]>.self)
    }
}
