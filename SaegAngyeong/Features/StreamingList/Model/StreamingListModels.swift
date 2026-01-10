//
//  StreamingListModels.swift
//  SaegAngyeong
//
//  Created by andev on 1/10/26.
//

import Foundation

struct StreamingListItemViewData {
    let id: String
    let title: String
    let description: String
    let durationText: String
    let viewCountText: String
    let likeCountText: String
    let thumbnailURL: URL
    let headers: [String: String]
}
