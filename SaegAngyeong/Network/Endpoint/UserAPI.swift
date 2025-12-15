//
//  UserAPI.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation
import Alamofire

enum UserAPI: APIEndpoint {
    case validateEmail(body: any Encodable)
    case join(body: any Encodable)
    case login(body: any Encodable)
    case loginKakao(body: any Encodable)
    case loginApple(body: any Encodable)
    case logout
    case updateDeviceToken(body: any Encodable)
    case fetchProfile(userID: String)
    case uploadProfileImage(files: [UploadFile])
    case myProfile
    case updateMyProfile(body: any Encodable)
    case search(nick: String?)
    case todayAuthor

    var path: String {
        switch self {
        case .validateEmail:
            return "v1/users/validation/email"
        case .join:
            return "v1/users/join"
        case .login:
            return "v1/users/login"
        case .loginKakao:
            return "v1/users/login/kakao"
        case .loginApple:
            return "v1/users/login/apple"
        case .logout:
            return "v1/users/logout"
        case .updateDeviceToken:
            return "v1/users/deviceToken"
        case .fetchProfile(let userID):
            return "v1/users/\(userID)/profile"
        case .uploadProfileImage:
            return "v1/users/profile/image"
        case .myProfile, .updateMyProfile:
            return "v1/users/me/profile"
        case .search:
            return "v1/users/search"
        case .todayAuthor:
            return "v1/users/today-author"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .validateEmail, .join, .login, .loginKakao, .loginApple, .logout, .uploadProfileImage:
            return .post
        case .updateDeviceToken:
            return .put
        case .fetchProfile, .myProfile, .search, .todayAuthor:
            return .get
        case .updateMyProfile:
            return .put
        }
    }

    var task: APITask {
        switch self {
        case .validateEmail(let body),
             .join(let body),
             .login(let body),
             .loginKakao(let body),
             .loginApple(let body),
             .updateMyProfile(let body),
             .updateDeviceToken(let body):
            return .requestJSON(body)

        case .logout, .myProfile, .fetchProfile, .todayAuthor:
            return .requestPlain

        case .uploadProfileImage(let files):
            return .uploadFiles(files)

        case .search(let nick):
            return .requestQuery(compactQuery([
                "nick": nick
            ]))
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .validateEmail, .join, .login, .loginKakao, .loginApple:
            return false
        default:
            return true
        }
    }
}
