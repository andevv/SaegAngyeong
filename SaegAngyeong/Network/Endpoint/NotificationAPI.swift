//
//  NotificationAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum NotificationAPI: APIEndpoint {
    case push(body: any Encodable)

    var path: String { "v1/notifications/push" }
    var method: HTTPMethod { .post }
    var task: APITask {
        switch self {
        case .push(let body):
            return .requestJSON(body)
        }
    }
    var requiresAuth: Bool { true }
}
