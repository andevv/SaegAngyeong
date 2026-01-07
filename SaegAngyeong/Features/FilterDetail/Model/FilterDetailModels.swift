//
//  FilterDetailModels.swift
//  SaegAngyeong
//
//  Created by andev on 1/1/26.
//

import Foundation

struct FilterDetailViewData {
    let filterID: String
    let title: String
    let category: String
    let description: String
    let price: Int
    let likeCount: Int
    let buyerCount: Int
    let isLiked: Bool
    let isDownloaded: Bool
    let originalImageURL: URL?
    let filteredImageURL: URL?
    let creatorName: String
    let creatorNick: String
    let creatorUserID: String
    let creatorIntroduction: String
    let creatorHashTags: [String]
    let creatorProfileURL: URL?
    let isOwnedByMe: Bool
    let metadataTitle: String
    let metadataLine1: String
    let metadataLine2: String
    let metadataLine3: String
    let metadataFormat: String
    let latitude: Double?
    let longitude: Double?
    let presets: [FilterPresetViewData]
    let requiresPurchase: Bool
    let isPurchased: Bool
    let headers: [String: String]

    func updating(isLiked: Bool, likeCount: Int) -> FilterDetailViewData {
        FilterDetailViewData(
            filterID: filterID,
            title: title,
            category: category,
            description: description,
            price: price,
            likeCount: likeCount,
            buyerCount: buyerCount,
            isLiked: isLiked,
            isDownloaded: isDownloaded,
            originalImageURL: originalImageURL,
            filteredImageURL: filteredImageURL,
            creatorName: creatorName,
            creatorNick: creatorNick,
            creatorUserID: creatorUserID,
            creatorIntroduction: creatorIntroduction,
            creatorHashTags: creatorHashTags,
            creatorProfileURL: creatorProfileURL,
            isOwnedByMe: isOwnedByMe,
            metadataTitle: metadataTitle,
            metadataLine1: metadataLine1,
            metadataLine2: metadataLine2,
            metadataLine3: metadataLine3,
            metadataFormat: metadataFormat,
            latitude: latitude,
            longitude: longitude,
            presets: presets,
            requiresPurchase: requiresPurchase,
            isPurchased: isPurchased,
            headers: headers
        )
    }

    func updating(metadataLine3: String) -> FilterDetailViewData {
        FilterDetailViewData(
            filterID: filterID,
            title: title,
            category: category,
            description: description,
            price: price,
            likeCount: likeCount,
            buyerCount: buyerCount,
            isLiked: isLiked,
            isDownloaded: isDownloaded,
            originalImageURL: originalImageURL,
            filteredImageURL: filteredImageURL,
            creatorName: creatorName,
            creatorNick: creatorNick,
            creatorUserID: creatorUserID,
            creatorIntroduction: creatorIntroduction,
            creatorHashTags: creatorHashTags,
            creatorProfileURL: creatorProfileURL,
            isOwnedByMe: isOwnedByMe,
            metadataTitle: metadataTitle,
            metadataLine1: metadataLine1,
            metadataLine2: metadataLine2,
            metadataLine3: metadataLine3,
            metadataFormat: metadataFormat,
            latitude: latitude,
            longitude: longitude,
            presets: presets,
            requiresPurchase: requiresPurchase,
            isPurchased: isPurchased,
            headers: headers
        )
    }
}

struct FilterPresetViewData {
    let iconName: String
    let valueText: String
}
