//
//  BannerDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 12/16/25.
//

import Foundation

struct BannerListResponseDTO: Decodable {
    let data: [BannerDTO]
}

struct BannerDTO: Decodable {
    let name: String
    let imageUrl: String
    let payload: BannerPayloadDTO
}

struct BannerPayloadDTO: Decodable {
    let type: String
    let value: String
}
