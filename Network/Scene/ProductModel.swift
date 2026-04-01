//
//  ProductModel.swift
//  Networking
//
//  Created by Salah Khaled on 01/03/2026.
//

import Foundation

// MARK: - Paramters
struct ProductParam: Encodable {
    var limit: Int
    var skip: Int
    var order: String
    var sortBy: String
}


// MARK: - Product
struct ProductModel: Codable, Identifiable {
    let id: Int?
    let title: String?
    let description: String?
    let category: String?
    let categorys: String?
    let price: Double?
    let thumbnail: String?
}
