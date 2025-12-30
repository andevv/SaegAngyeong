//
//  UserDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import Foundation

struct UserProfileResponseDTO: Decodable {
    let userID: String
    let email: String?
    let nick: String
    let name: String?
    let introduction: String?
    let profileImage: String?
    let phoneNum: String?
    let hashTags: [String]?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email
        case nick
        case name
        case introduction
        case profileImage
        case phoneNum
        case hashTags
    }
}
