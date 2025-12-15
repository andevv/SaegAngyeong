//
//  BannerAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum BannerAPI: APIEndpoint {
    case main

    var path: String { "v1/banners/main" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
    var requiresAuth: Bool { true }
}
