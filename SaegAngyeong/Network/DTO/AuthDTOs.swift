//
//  AuthDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let deviceToken: String?
}

struct KakaoLoginRequest: Encodable {
    let oauthToken: String
    let deviceToken: String?
}

struct AppleLoginRequest: Encodable {
    let idToken: String
    let deviceToken: String?
}

struct JoinRequest: Encodable {
    let email: String
    let password: String
    let nick: String
    let name: String?
    let introduction: String?
    let phoneNum: String?
    let hashTags: [String]?
    let deviceToken: String?
}

struct DeviceTokenRequest: Encodable {
    let deviceToken: String
}

struct LoginResponseDTO: Decodable {
    let userID: String
    let email: String?
    let nick: String
    let profileImage: String?
    let accessToken: String
    let refreshToken: String
    let name: String?
    let introduction: String?
    let phoneNum: String?
    let hashTags: [String]?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email
        case nick
        case profileImage
        case accessToken
        case refreshToken
        case name
        case introduction
        case phoneNum
        case hashTags
    }
}

struct RefreshTokenResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}
