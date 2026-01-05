//
//  Chat.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

struct ChatRoom {
    let id: String
    let name: String?
    let participants: [UserSummary]
    let lastMessage: ChatMessage?
    let createdAt: Date
    let updatedAt: Date
}

struct ChatMessage {
    let id: String
    let roomID: String
    let sender: UserSummary
    let content: String?
    let fileURLs: [URL]
    let createdAt: Date
}

struct ChatMessageDraft {
    let content: String?
    let fileURLs: [URL]
}
