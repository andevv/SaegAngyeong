//
//  VideoAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum VideoAPI: APIEndpoint {
    case list(next: String?, limit: Int?)
    case stream(videoID: String)
    case like(videoID: String, body: any Encodable)

    var path: String {
        switch self {
        case .list:
            return "v1/videos"
        case .stream(let id):
            return "v1/videos/\(id)/stream"
        case .like(let id, _):
            return "v1/videos/\(id)/like"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .stream:
            return .get
        case .like:
            return .post
        }
    }

    var task: APITask {
        switch self {
        case .list(let next, let limit):
            return .requestQuery(compactQuery([
                "next": next,
                "limit": limit
            ]))
        case .stream:
            return .requestPlain
        case .like(_, let body):
            return .requestJSON(body)
        }
    }

    var requiresAuth: Bool { true }
}
