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

// Filter List

struct FilterSummaryPaginationResponseDTO: Decodable {
    let data: [FilterSummaryItemDTO]
    let nextCursor: String

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct FilterSummaryItemDTO: Decodable {
    let filterID: String
    let category: String
    let title: String
    let description: String
    let files: [String]
    let creator: UserInfoResponseDTO
    let isLiked: Bool
    let likeCount: Int
    let buyerCount: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case filterID = "filter_id"
        case category
        case title
        case description
        case files
        case creator
        case isLiked = "is_liked"
        case likeCount = "like_count"
        case buyerCount = "buyer_count"
        case createdAt
        case updatedAt
    }
}

struct UserInfoResponseDTO: Decodable {
    let userID: String
    let nick: String
    let name: String?
    let introduction: String?
    let profileImage: String?
    let hashTags: [String]?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick
        case name
        case introduction
        case profileImage
        case hashTags
    }
}

// Today Author

struct TodayAuthorResponseDTO: Decodable {
    let author: TodayAuthorAuthorDTO
    let filters: [TodayAuthorFilterDTO]
}

struct TodayAuthorAuthorDTO: Decodable {
    let userID: String
    let nick: String
    let name: String
    let introduction: String
    let description: String
    let profileImage: String?
    let hashTags: [String]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick
        case name
        case introduction
        case description
        case profileImage
        case hashTags
    }
}

struct TodayAuthorFilterDTO: Decodable {
    let filterID: String
    let category: String
    let title: String
    let description: String
    let files: [String]
    let creator: TodayAuthorCreatorDTO
    let isLiked: Bool
    let likeCount: Int
    let buyerCount: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case filterID = "filter_id"
        case category
        case title
        case description
        case files
        case creator
        case isLiked = "is_liked"
        case likeCount = "like_count"
        case buyerCount = "buyer_count"
        case createdAt
        case updatedAt
    }
}

struct TodayAuthorCreatorDTO: Decodable {
    let userID: String
    let nick: String
    let name: String
    let introduction: String
    let profileImage: String?
    let hashTags: [String]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick
        case name
        case introduction
        case profileImage
        case hashTags
    }
}
