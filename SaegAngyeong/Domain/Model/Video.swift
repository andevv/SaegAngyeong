//
//  Video.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct Video {
    let id: String
    let fileName: String
    let title: String
    let description: String
    let duration: TimeInterval
    let thumbnailURL: URL
    let availableQualities: [String]
    let viewCount: Int
    let likeCount: Int
    let isLiked: Bool
    let createdAt: Date
}

struct StreamInfo {
    let videoID: String
    let streamURL: URL
    let qualities: [URL]
    let subtitles: [URL]
}
