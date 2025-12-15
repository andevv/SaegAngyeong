//
//  FilterDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct TodayFilterResponseDTO: Decodable {
    let filterID: String
    let title: String
    let introduction: String
    let description: String
    let files: [String]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case filterID = "filter_id"
        case title
        case introduction
        case description
        case files
        case createdAt
        case updatedAt
    }
}
