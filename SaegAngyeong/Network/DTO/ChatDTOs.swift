//
//  ChatDTOs.swift
//  SaegAngyeong
//
//  Created by andev on 1/5/26.
//

import Foundation

struct ChatRoomListResponseDTO: Decodable {
    let data: [ChatRoomDTO]
}

struct ChatRoomDTO: Decodable {
    let roomID: String
    let createdAt: String
    let updatedAt: String
    let participants: [ChatUserDTO]
    let lastChat: ChatMessageDTO?

    enum CodingKeys: String, CodingKey {
        case roomID = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }
}

struct ChatUserDTO: Decodable {
    let userID: String
    let nick: String
    let name: String?
    let introduction: String?
    let profileImage: String?
    let hashTags: [String]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case nick
        case name
        case introduction
        case profileImage
        case hashTags
    }
}

struct ChatMessageDTO: Decodable {
    let chatID: String
    let roomID: String
    let content: String?
    let createdAt: String
    let updatedAt: String
    let sender: ChatUserDTO
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case roomID = "room_id"
        case content
        case createdAt
        case updatedAt
        case sender
        case files
    }
}
