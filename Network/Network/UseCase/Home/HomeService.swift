//
//  HomeService.swift
//  Network
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation

enum HomeService: ServiceProtocol {
    
    case getProducts(_ params: ProductParam)
    case addProduct(_ product: ProductModel)
    
    
    var url: String { API.baseUrl }
    
    
    var path: String {
        switch self {
        case .getProducts: API.products
        case .addProduct: API.addProducts
        }
    }
    
    
    var method: HTTPMethod {
        switch self {
        case .getProducts: .GET
        case .addProduct: .POST
        }
    }
    
    
    var parameters: Parameters? {
        switch self {
        case .getProducts(let params): params.asDictionary()
        default: nil
        }
    }
    
    
    var headers: Headers? { nil }
    
    
    var body: Encodable? {
        switch self {
        case .addProduct(let product): product
        default: nil
        }
    }
}
