//
//  VideoDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import Foundation

struct VideoListResponseDTO: Decodable {
    let data: [VideoDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct VideoDTO: Decodable {
    let videoID: String
    let fileName: String
    let title: String
    let description: String
    let duration: Double
    let thumbnailURL: String
    let availableQualities: [String]
    let viewCount: Int
    let likeCount: Int
    let isLiked: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case videoID = "video_id"
        case fileName = "file_name"
        case title
        case description
        case duration
        case thumbnailURL = "thumbnail_url"
        case availableQualities = "available_qualities"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case isLiked = "is_liked"
        case createdAt
    }
}

struct VideoStreamResponseDTO: Decodable {
    let videoID: String
    let streamURL: String
    let qualities: [VideoStreamQualityDTO]?
    let subtitles: [VideoStreamSubtitleDTO]?

    enum CodingKeys: String, CodingKey {
        case videoID = "video_id"
        case streamURL = "stream_url"
        case qualities
        case subtitles
    }
}

struct VideoStreamQualityDTO: Decodable {
    let quality: String
    let url: String
}

struct VideoStreamSubtitleDTO: Decodable {
    let language: String
    let name: String
    let isDefault: Bool
    let url: String

    enum CodingKeys: String, CodingKey {
        case language
        case name
        case isDefault = "is_default"
        case url
    }
}

struct VideoLikeRequestDTO: Encodable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
