//
//  Order.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct Order {
    let id: String
    let code: String
    let totalPrice: Int
    let filter: FilterSummary
    let paidAt: Date?
    let createdAt: Date
    let updatedAt: Date
}

struct FilterSummary {
    let id: String
    let category: String
    let title: String
    let description: String
    let files: [URL]
    let price: Int
    let creator: UserSummary
    let filterValues: FilterValues
    let createdAt: Date
    let updatedAt: Date
}
