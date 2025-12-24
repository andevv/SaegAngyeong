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

struct FilterLikeRequestDTO: Encodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}

struct FilterLikeResponseDTO: Decodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}

// Filter Detail

struct FilterDetailResponseDTO: Decodable {
    let filterID: String
    let category: String
    let title: String
    let description: String
    let files: [String]
    let price: Int
    let creator: UserInfoResponseDTO
    let photoMetadata: PhotoMetadataDTO?
    let filterValues: FilterValuesDTO?
    let isLiked: Bool
    let isDownloaded: Bool
    let likeCount: Int
    let buyerCount: Int
    let comments: [FilterCommentResponseDTO]?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case filterID = "filter_id"
        case category
        case title
        case description
        case files
        case price
        case creator
        case photoMetadata
        case filterValues
        case isLiked = "is_liked"
        case isDownloaded = "is_downloaded"
        case likeCount = "like_count"
        case buyerCount = "buyer_count"
        case comments
        case createdAt
        case updatedAt
    }
}

struct PhotoMetadataDTO: Decodable {
    let camera: String?
    let lensInfo: String?
    let focalLength: Double?
    let aperture: Double?
    let iso: Int?
    let shutterSpeed: String?
    let pixelWidth: Int?
    let pixelHeight: Int?
    let fileSize: Double?
    let format: String?
    let dateTimeOriginal: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case camera
        case lensInfo = "lens_info"
        case focalLength = "focal_length"
        case aperture
        case iso
        case shutterSpeed = "shutter_speed"
        case pixelWidth = "pixel_width"
        case pixelHeight = "pixel_height"
        case fileSize = "file_size"
        case format
        case dateTimeOriginal = "date_time_original"
        case latitude
        case longitude
    }
}

struct FilterValuesDTO: Decodable {
    let brightness: Double?
    let exposure: Double?
    let contrast: Double?
    let saturation: Double?
    let sharpness: Double?
    let blur: Double?
    let vignette: Double?
    let noiseReduction: Double?
    let highlights: Double?
    let shadows: Double?
    let temperature: Double?
    let blackPoint: Double?

    enum CodingKeys: String, CodingKey {
        case brightness
        case exposure
        case contrast
        case saturation
        case sharpness
        case blur
        case vignette
        case noiseReduction = "noise_reduction"
        case highlights
        case shadows
        case temperature
        case blackPoint = "black_point"
    }
}

struct FilterCommentResponseDTO: Decodable {
    let commentID: String
    let content: String
    let createdAt: String
    let creator: UserInfoResponseDTO
    let replies: [FilterCommentResponseDTO]

    enum CodingKeys: String, CodingKey {
        case commentID = "comment_id"
        case content
        case createdAt
        case creator
        case replies
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
