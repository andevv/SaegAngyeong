//
//  Post.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct Geolocation {
    let latitude: Double
    let longitude: Double
}

struct Post {
    let id: String
    let category: String
    let title: String
    let content: String
    let files: [URL]
    let geolocation: Geolocation?
    let creator: UserSummary
    let createdAt: Date
    let updatedAt: Date
    let isLiked: Bool
    let likeCount: Int
    let comments: [Comment]
}

struct PostDraft {
    let category: String
    let title: String
    let content: String
    let latitude: Double
    let longitude: Double
    let files: [URL]
}

struct PostLikeToggle {
    let likeStatus: Bool
}
