//
//  FeedModels.swift
//  SaegAngyeong
//
//  Created by andev on 1/1/26.
//

import Foundation
import UIKit

enum FeedOrder: CaseIterable {
    case popularity
    case purchase
    case latest

    var title: String {
        switch self {
        case .popularity: return "인기순"
        case .purchase: return "구매순"
        case .latest: return "최신순"
        }
    }

    var apiValue: String {
        switch self {
        case .popularity: return "popularity"
        case .purchase: return "purchase"
        case .latest: return "latest"
        }
    }
}

struct FeedRankViewData {
    let id: String
    let title: String
    let creatorNick: String
    let category: String
    let imageURL: URL?
    let headers: [String: String]
    let rank: Int
    let likeCount: Int
    let buyerCount: Int
}

struct FeedItemViewData {
    let id: String
    let title: String
    let creatorNick: String
    let category: String
    let description: String
    let imageURL: URL?
    let likeCount: Int
    let isLiked: Bool
    let headers: [String: String]

    var masonryHeight: CGFloat {
        let seed = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let options: [CGFloat] = [180, 210, 240, 270]
        return options[seed % options.count]
    }

    func updating(isLiked: Bool, likeCount: Int) -> FeedItemViewData {
        FeedItemViewData(
            id: id,
            title: title,
            creatorNick: creatorNick,
            category: category,
            description: description,
            imageURL: imageURL,
            likeCount: likeCount,
            isLiked: isLiked,
            headers: headers
        )
    }
}

struct FeedLikeAction {
    let filterID: String
}
