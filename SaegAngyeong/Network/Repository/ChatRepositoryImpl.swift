//
//  ChatRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 1/5/26.
//

import Foundation
import Combine

final class ChatRepositoryImpl: ChatRepository {
    private let network: NetworkProviding

    init(network: NetworkProviding) {
        self.network = network
    }

    func createRoom(name: String?) -> AnyPublisher<ChatRoom, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented"))
            .eraseToAnyPublisher()
    }

    func fetchRooms() -> AnyPublisher<[ChatRoom], DomainError> {
        network.request(ChatRoomListResponseDTO.self, endpoint: ChatAPI.fetchRooms)
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return [] }
                return dto.data.map { room in
                    let participants = room.participants.map { user in
                        UserSummary(
                            id: user.userID,
                            nick: user.nick,
                            profileImageURL: user.profileImage.flatMap { self.buildURL(from: $0) },
                            name: user.name,
                            introduction: user.introduction,
                            hashTags: user.hashTags
                        )
                    }
                    let lastMessage = room.lastChat.map { message in
                        ChatMessage(
                            id: message.chatID,
                            roomID: message.roomID,
                            sender: UserSummary(
                                id: message.sender.userID,
                                nick: message.sender.nick,
                                profileImageURL: message.sender.profileImage.flatMap { self.buildURL(from: $0) },
                                name: message.sender.name,
                                introduction: message.sender.introduction,
                                hashTags: message.sender.hashTags
                            ),
                            content: message.content,
                            fileURLs: message.files.compactMap { self.buildURL(from: $0) },
                            createdAt: self.parseISODate(message.createdAt)
                        )
                    }
                    return ChatRoom(
                        id: room.roomID,
                        name: nil,
                        participants: participants,
                        lastMessage: lastMessage,
                        createdAt: self.parseISODate(room.createdAt),
                        updatedAt: self.parseISODate(room.updatedAt)
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    func sendMessage(roomID: String, draft: ChatMessageDraft) -> AnyPublisher<ChatMessage, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented"))
            .eraseToAnyPublisher()
    }

    func fetchMessages(roomID: String, next: String?) -> AnyPublisher<Paginated<ChatMessage>, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented"))
            .eraseToAnyPublisher()
    }

    func uploadFiles(roomID: String, files: [UploadFileData]) -> AnyPublisher<[URL], DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented"))
            .eraseToAnyPublisher()
    }
}

private extension ChatRepositoryImpl {
    func parseISODate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value) ?? Date()
    }

    func buildURL(from path: String) -> URL? {
        if let url = URL(string: path), url.scheme != nil {
            return url
        }
        guard let base = URL(string: AppConfig.baseURL) else { return nil }
        var normalized = path
        if normalized.hasPrefix("/") {
            normalized.removeFirst()
        }
        if normalized.hasPrefix("data/") || normalized.hasPrefix("v1/") {
            return base.appendingPathComponent(normalized)
        }
        return base.appendingPathComponent("v1/" + normalized)
    }
}
