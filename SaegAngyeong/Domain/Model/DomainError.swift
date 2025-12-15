//
//  DomainError.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

/// 앱 전반에서 사용하는 도메인 에러
enum DomainError: Error {
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validation(message: String)
    case server(message: String?)
    case decoding
    case network
    case unknown(message: String?)
}
