//
//  Paginated.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct Paginated<T> {
    let items: [T]
    let nextCursor: String?
}
