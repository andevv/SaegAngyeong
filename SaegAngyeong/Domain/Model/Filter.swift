//
//  Filter.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct FilterValues {
    let brightness: Double?
    let exposure: Double?
    let contrast: Double?
    let saturation: Double?
    let sharpness: Double?
    let temperature: Double?
    let highlight: Double?
    let shadow: Double?
    let vignette: Double?
    let grain: Double?
    let blur: Double?
    let fade: Double?
}

struct PhotoMetadata {
    let camera: String?
    let lensInfo: String?
    let focalLength: Double?
    let aperture: Double?
    let shutterSpeed: String?
    let iso: Int?
    let whiteBalance: String?
    let location: String?
    let takenAt: Date?
}

struct Filter {
    let id: String
    let category: String
    let title: String
    let introduction: String?
    let description: String
    let files: [URL]
    let price: Int
    let filterValues: FilterValues
    let photoMetadata: PhotoMetadata?
    let creator: UserSummary
    let createdAt: Date
    let updatedAt: Date
    let comments: [Comment]
    let isLiked: Bool
    let likeCount: Int
    let buyerCount: Int
    let isDownloaded: Bool
}

struct FilterDraft {
    let category: String
    let title: String
    let price: Int
    let description: String
    let files: [URL]
    let photoMetadata: PhotoMetadata?
    let filterValues: FilterValues
}

struct FilterLikeToggle {
    let likeStatus: Bool
}
