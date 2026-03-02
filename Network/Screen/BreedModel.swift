//
//  Base.swift
//  Network
//
//  Created by Salah Khaled on 01/03/2026.
//


import Foundation


// MARK: - Datum
struct BreedModel: Codable, Identifiable {
    let id: String?
    let type: String?
    let attributes: AttributesModel
}

// MARK: - Attributes
struct AttributesModel: Codable {
    let name: String?
    let description: String?
    let life, maleWeight, femaleWeight: MinMaxModel?
    let hypoallergenic: Bool?

    enum CodingKeys: String, CodingKey {
        case name, description, life
        case maleWeight = "male_weight"
        case femaleWeight = "female_weight"
        case hypoallergenic
    }
}

// MARK: - Min Max Model
struct MinMaxModel: Codable {
    let max, min: Int?
}
