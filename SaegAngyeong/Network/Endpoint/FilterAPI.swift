//
//  FilterAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum FilterAPI: APIEndpoint {
    case uploadFiles(files: [UploadFile])
    case create(body: any Encodable)
    case list(next: String?, limit: Int?, category: String?, orderBy: String?)
    case detail(id: String)
    case update(id: String, body: any Encodable)
    case delete(id: String)
    case createComment(filterID: String, body: any Encodable)
    case updateComment(filterID: String, commentID: String, body: any Encodable)
    case deleteComment(filterID: String, commentID: String)
    case like(filterID: String, body: any Encodable)
    case userFilters(userID: String, next: String?, limit: Int?, category: String?)
    case likedFilters(category: String?, next: String?, limit: Int?)
    case hotTrend
    case todayFilter

    var path: String {
        switch self {
        case .uploadFiles:
            return "v1/filters/files"
        case .create, .list:
            return "v1/filters"
        case .detail(let id), .update(let id, _), .delete(let id):
            return "v1/filters/\(id)"
        case .createComment(let id, _):
            return "v1/filters/\(id)/comments"
        case .updateComment(let id, let commentID, _),
             .deleteComment(let id, let commentID):
            return "v1/filters/\(id)/comments/\(commentID)"
        case .like(let id, _):
            return "v1/filters/\(id)/like"
        case .userFilters(let userID, _, _, _):
            return "v1/filters/users/\(userID)"
        case .likedFilters:
            return "v1/filters/likes/me"
        case .hotTrend:
            return "v1/filters/hot-trend"
        case .todayFilter:
            return "v1/filters/today-filter"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create, .uploadFiles, .createComment, .like:
            return .post
        case .list, .detail, .userFilters, .likedFilters, .hotTrend, .todayFilter:
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
             .createComment(_, let body),
             .updateComment(_, _, let body),
             .like(_, let body):
            return .requestJSON(body)

        case .list(let next, let limit, let category, let orderBy):
            return .requestQuery(compactQuery([
                "next": next,
                "limit": limit,
                "category": category,
                "order_by": orderBy
            ]))

        case .userFilters(_, let next, let limit, let category):
            return .requestQuery(compactQuery([
                "next": next,
                "limit": limit,
                "category": category
            ]))

        case .likedFilters(let category, let next, let limit):
            return .requestQuery(compactQuery([
                "category": category,
                "next": next,
                "limit": limit
            ]))

        case .detail, .delete, .deleteComment, .hotTrend, .todayFilter:
            return .requestPlain
        }
    }

    var requiresAuth: Bool { true }
}
