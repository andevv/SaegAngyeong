//
//  ChatLocalStore.swift
//  SaegAngyeong
//
//  Created by andev on 1/6/26.
//

import Foundation
import RealmSwift

final class ChatLocalStore {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }

    func observeMessages(
        roomID: String,
        onUpdate: @escaping ([ChatMessage]) -> Void
    ) -> NotificationToken? {
        do {
            let realm = try Realm(configuration: configuration)
            let results = realm.objects(ChatMessageObject.self)
                .where { $0.roomID == roomID }
                .sorted(byKeyPath: "createdAt", ascending: true)
            return results.observe { changes in
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    let messages = collection.map { $0.toDomain() }
                    onUpdate(Array(messages))
                case .error:
                    break
                }
            }
        } catch {
            return nil
        }
    }

    func save(messages: [ChatMessage]) {
        guard !messages.isEmpty else { return }
        do {
            let realm = try Realm(configuration: configuration)
            try realm.write {
                messages.forEach { message in
                    let object = ChatMessageObject(message: message)
                    realm.add(object, update: .modified)
                }
            }
        } catch { }
    }

    func contains(messageID: String) -> Bool {
        (try? Realm(configuration: configuration)
            .object(ofType: ChatMessageObject.self, forPrimaryKey: messageID)) != nil
    }

    func lastMessageID(roomID: String) -> String? {
        do {
            let realm = try Realm(configuration: configuration)
            let result = realm.objects(ChatMessageObject.self)
                .where { $0.roomID == roomID }
                .sorted(byKeyPath: "createdAt", ascending: true)
                .last
            return result?.id
        } catch {
            return nil
        }
    }
}
