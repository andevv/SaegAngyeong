//
//  ChatMessageObject.swift
//  SaegAngyeong
//
//  Created by andev on 1/6/26.
//

import Foundation
import RealmSwift

final class ChatMessageObject: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var roomID: String
    @Persisted var senderID: String
    @Persisted var senderNick: String
    @Persisted var senderName: String?
    @Persisted var senderProfileURL: String?
    @Persisted var content: String?
    @Persisted var createdAt: Date
    @Persisted var fileURLs: List<String>

    convenience init(message: ChatMessage) {
        self.init()
        id = message.id
        roomID = message.roomID
        senderID = message.sender.id
        senderNick = message.sender.nick
        senderName = message.sender.name
        senderProfileURL = message.sender.profileImageURL?.absoluteString
        content = message.content
        createdAt = message.createdAt
        fileURLs.removeAll()
        fileURLs.append(objectsIn: message.fileURLs.map { $0.absoluteString })
    }

    func toDomain() -> ChatMessage {
        ChatMessage(
            id: id,
            roomID: roomID,
            sender: UserSummary(
                id: senderID,
                nick: senderNick,
                profileImageURL: senderProfileURL.flatMap { URL(string: $0) },
                name: senderName,
                introduction: nil,
                hashTags: []
            ),
            content: content,
            fileURLs: fileURLs.compactMap { URL(string: $0) },
            createdAt: createdAt
        )
    }
}
