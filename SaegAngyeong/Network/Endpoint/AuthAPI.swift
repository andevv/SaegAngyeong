//
//  AuthAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum AuthAPI: APIEndpoint {
    case refresh(refreshToken: String)

    var path: String { "v1/auth/refresh" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
    var requiresAuth: Bool { true }

    var additionalHeaders: HTTPHeaders {
        switch self {
        case .refresh(let refreshToken):
            return HTTPHeaders([HTTPHeader(name: "RefreshToken", value: refreshToken)])
        }
    }
}
