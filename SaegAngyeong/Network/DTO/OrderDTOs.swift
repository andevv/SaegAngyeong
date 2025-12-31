//
//  OrderDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import Foundation

struct OrderCreateRequestDTO: Encodable {
    let filterID: String
    let totalPrice: Int

    enum CodingKeys: String, CodingKey {
        case filterID = "filter_id"
        case totalPrice = "total_price"
    }
}

struct OrderCreateResponseDTO: Decodable {
    let orderID: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case createdAt
        case updatedAt
    }
}

struct OrderResponseDTO: Decodable {
    let orderID: String
    let orderCode: String
    let totalPrice: Int?
    let filter: FilterSummaryResponseDTO_Order
    let paidAt: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderID = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case filter
        case paidAt
        case createdAt
        case updatedAt
    }
}

struct FilterSummaryResponseDTO_Order: Decodable {
    let filterID: String
    let category: String
    let title: String
    let description: String
    let files: [String]
    let price: Int
    let creator: UserInfoResponseDTO
    let filterValues: FilterValuesDTO
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case filterID = "id"
        case category
        case title
        case description
        case files
        case price
        case creator
        case filterValues
        case createdAt
        case updatedAt
    }
}

struct OrderListResponseDTO: Decodable {
    let data: [OrderResponseDTO]
}
