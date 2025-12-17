//
//  User.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct UserSummary {
    let id: String
    let nick: String
    let profileImageURL: URL?
}

struct UserProfile {
    let id: String
    let email: String?
    let nick: String
    let name: String?
    let introduction: String?
    let description: String?
    let phoneNumber: String?
    let profileImageURL: URL?
    let hashTags: [String]
}

struct UserProfileUpdate {
    let nick: String?
    let name: String?
    let introduction: String?
    let description: String?
    let phoneNumber: String?
    let profileImageURL: URL?
    let hashTags: [String]?
}
