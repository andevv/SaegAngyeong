//
//  CommonAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum CommonAPI: APIEndpoint {
    case health

    var path: String { "common" }
    var method: HTTPMethod { .get }
    var task: APITask { .requestPlain }
}
