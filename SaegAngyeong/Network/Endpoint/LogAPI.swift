//
//  LogAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum LogAPI: APIEndpoint {
    case fetch

    var path: String { "v1/log" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
    var requiresAuth: Bool { false }
}
