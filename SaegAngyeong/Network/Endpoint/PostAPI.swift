//
//  PostAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum PostAPI: APIEndpoint {
    case uploadFiles(files: [UploadFile])
    case create(body: any Encodable)
    case geolocation(category: String?, longitude: Double?, latitude: Double?, maxDistance: Double?, limit: Int?, next: String?, orderBy: String?)
    case search(title: String?)
    case detail(id: String)
    case update(id: String, body: any Encodable)
    case delete(id: String)
    case like(postID: String, body: any Encodable)
    case userPosts(userID: String, category: String?, limit: Int?, next: String?)
    case likedPosts(category: String?, next: String?, limit: String?)
    case createComment(postID: String, body: any Encodable)
    case updateComment(postID: String, commentID: String, body: any Encodable)
    case deleteComment(postID: String, commentID: String)

    var path: String {
        switch self {
        case .uploadFiles:
            return "v1/posts/files"
        case .create:
            return "v1/posts"
        case .geolocation:
            return "v1/posts/geolocation"
        case .search:
            return "v1/posts/search"
        case .detail(let id), .update(let id, _), .delete(let id):
            return "v1/posts/\(id)"
        case .like(let id, _):
            return "v1/posts/\(id)/like"
        case .userPosts(let userID, _, _, _):
            return "v1/posts/users/\(userID)"
        case .likedPosts:
            return "v1/posts/likes/me"
        case .createComment(let id, _):
            return "v1/posts/\(id)/comments"
        case .updateComment(let postID, let commentID, _),
             .deleteComment(let postID, let commentID):
            return "v1/posts/\(postID)/comments/\(commentID)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .uploadFiles, .create, .like, .createComment:
            return .post
        case .geolocation, .search, .detail, .userPosts, .likedPosts:
            return .get
        case .update, .updateComment:
            return .put
        case .delete, .deleteComment:
            return .delete
        }
    }

    var task: APITask {
        switch self {
        case .uploadFiles(let files):
            return .uploadFiles(files)

        case .create(let body),
             .update(_, let body),
             .like(_, let body),
             .createComment(_, let body),
             .updateComment(_, _, let body):
            return .requestJSON(body)

        case .geolocation(let category, let longitude, let latitude, let maxDistance, let limit, let next, let orderBy):
            return .requestQuery(compactQuery([
                "category": category,
                "longitude": longitude,
                "latitude": latitude,
                "maxDistance": maxDistance,
                "limit": limit,
                "next": next,
                "order_by": orderBy
            ]))

        case .search(let title):
            return .requestQuery(compactQuery([
                "title": title
            ]))

        case .userPosts(_, let category, let limit, let next):
            return .requestQuery(compactQuery([
                "category": category,
                "limit": limit,
                "next": next
            ]))

        case .likedPosts(let category, let next, let limit):
            return .requestQuery(compactQuery([
                "category": category,
                "next": next,
                "limit": limit
            ]))

        case .detail, .delete, .deleteComment:
            return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}
