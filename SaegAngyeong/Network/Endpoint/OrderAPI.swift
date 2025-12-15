//
//  OrderAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum OrderAPI: APIEndpoint {
    case create(body: any Encodable)
    case list

    var path: String { "v1/orders" }

    var method: HTTPMethod {
        switch self {
        case .create: return .post
        case .list: return .get
        }
    }

    var task: APITask {
        switch self {
        case .create(let body): return .requestJSON(body)
        case .list: return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}
