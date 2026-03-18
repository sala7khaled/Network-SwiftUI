//
//  HomeRepo.swift
//  Networking
//
//  Created by Salah Khaled on 02/03/2026.
//

import Foundation

class HomeRepo: Repo {
    
    func fetchProducts(params: ProductParam) async -> Result<BaseResponse<[ProductModel]>, APIError> {
        do {
            let response: BaseResponse<[ProductModel]> = try await network.call(HomeService.getProducts(params))
            return .success(response)
        } catch {
            return .failure(network.mapError(error))
        }
    }
}
