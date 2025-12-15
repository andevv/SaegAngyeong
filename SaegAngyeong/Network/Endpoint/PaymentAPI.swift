//
//  PaymentAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum PaymentAPI: APIEndpoint {
    case validate(body: any Encodable)
    case detail(orderCode: String)

    var path: String {
        switch self {
        case .validate: return "v1/payments/validation"
        case .detail(let code): return "v1/payments/\(code)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .validate: return .post
        case .detail: return .get
        }
    }

    var task: APITask {
        switch self {
        case .validate(let body): return .requestJSON(body)
        case .detail: return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}
