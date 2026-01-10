//
//  HomeModels.swift
//  SaegAngyeong
//
//  Created by andev on 1/10/26.
//

import Foundation

struct HighlightViewData {
    let filterID: String?
    let title: String
    let introduction: String
    let description: String
    let imageURL: URL?
    let headers: [String: String]
}

struct BannerViewData {
    let title: String
    let imageURL: URL?
    let headers: [String: String]
    let linkURL: URL?
    let payloadType: String?
}

struct HotTrendViewData {
    let id: String
    let title: String
    let likeCount: Int
    let imageURL: URL?
    let headers: [String: String]
}

struct TodayAuthorViewData {
    let name: String
    let nick: String
    let introduction: String
    let description: String
    let profileImageURL: URL?
    let tags: [String]
    let filters: [AuthorFilterViewData]
    let headers: [String: String]
}

struct AuthorFilterViewData {
    let id: String
    let title: String
    let imageURL: URL?
    let headers: [String: String]
}

struct CategoryViewData {
    let title: String
    let iconName: String

    static let defaults: [CategoryViewData] = [
        .init(title: "푸드", iconName: "Category_Food"),
        .init(title: "인물", iconName: "Category_People"),
        .init(title: "풍경", iconName: "Category_Landscape"),
        .init(title: "별", iconName: "Category_Star"),
        .init(title: "야경", iconName: "Category_Night")
    ]
}
