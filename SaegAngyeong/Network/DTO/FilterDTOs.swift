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

struct HotTrendResponseDTO: Decodable {
    let data: [HotTrendItemDTO]
}

struct HotTrendItemDTO: Decodable {
    let id: String
    let category: String?
    let title: String
    let description: String?
    let files: [String]
    let likeCount: Int
    let isLiked: Bool?
    let buyerCount: Int?

    enum CodingKeys: String, CodingKey {
        case id = "filter_id"
        case category
        case title
        case description
        case files
        case likeCount = "like_count"
        case isLiked = "is_liked"
        case buyerCount = "buyer_count"
    }
}
