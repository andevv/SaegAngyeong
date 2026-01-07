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

    func createRoom(opponentID: String) -> AnyPublisher<ChatRoom, DomainError> {
        let body = ChatRoomCreateRequestDTO(opponentID: opponentID)
        return network.request(ChatRoomDTO.self, endpoint: ChatAPI.createRoom(body: body))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else {
                    return ChatRoom(id: dto.roomID, name: nil, participants: [], lastMessage: nil, createdAt: Date(), updatedAt: Date())
                }
                return self.mapRoom(dto)
            }
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
        let files = draft.fileURLs.map { mapFilePath(from: $0) }
        let body = ChatMessageSendRequestDTO(content: draft.content, files: files)
        return network.request(ChatMessageDTO.self, endpoint: ChatAPI.sendMessage(roomID: roomID, body: body))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else {
                    return ChatMessage(
                        id: dto.chatID,
                        roomID: dto.roomID,
                        sender: UserSummary(
                            id: dto.sender.userID,
                            nick: dto.sender.nick,
                            profileImageURL: nil,
                            name: dto.sender.name,
                            introduction: dto.sender.introduction,
                            hashTags: dto.sender.hashTags
                        ),
                        content: dto.content,
                        fileURLs: [],
                        createdAt: Date()
                    )
                }
                return self.mapMessage(dto)
            }
            .eraseToAnyPublisher()
    }

    func fetchMessages(roomID: String, next: String?) -> AnyPublisher<Paginated<ChatMessage>, DomainError> {
        network.request(ChatMessageListResponseDTO.self, endpoint: ChatAPI.fetchMessages(roomID: roomID, next: next))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return Paginated(items: [], nextCursor: nil) }
                let items = dto.data.map { self.mapMessage($0) }
                return Paginated(items: items, nextCursor: dto.nextCursor)
            }
            .eraseToAnyPublisher()
    }

    func uploadFiles(roomID: String, files: [UploadFileData]) -> AnyPublisher<[URL], DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented"))
            .eraseToAnyPublisher()
    }
}

private extension ChatRepositoryImpl {
    func mapRoom(_ room: ChatRoomDTO) -> ChatRoom {
        let participants = room.participants.map { user in
            UserSummary(
                id: user.userID,
                nick: user.nick,
                profileImageURL: user.profileImage.flatMap { buildURL(from: $0) },
                name: user.name,
                introduction: user.introduction,
                hashTags: user.hashTags
            )
        }
        let lastMessage = room.lastChat.map { mapMessage($0) }
        return ChatRoom(
            id: room.roomID,
            name: nil,
            participants: participants,
            lastMessage: lastMessage,
            createdAt: parseISODate(room.createdAt),
            updatedAt: parseISODate(room.updatedAt)
        )
    }

    func mapMessage(_ message: ChatMessageDTO) -> ChatMessage {
        ChatMessage(
            id: message.chatID,
            roomID: message.roomID,
            sender: UserSummary(
                id: message.sender.userID,
                nick: message.sender.nick,
                profileImageURL: message.sender.profileImage.flatMap { buildURL(from: $0) },
                name: message.sender.name,
                introduction: message.sender.introduction,
                hashTags: message.sender.hashTags
            ),
            content: message.content,
            fileURLs: message.files.compactMap { buildURL(from: $0) },
            createdAt: parseISODate(message.createdAt)
        )
    }

    func parseISODate(_ value: String) -> Date {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        if let date = fallbackFormatter.date(from: value) {
            return date
        }
        return Date()
    }

    func mapFilePath(from url: URL) -> String {
        var path = url.path
        if path.hasPrefix("/v1/") {
            path.removeFirst(3)
        }
        return path
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
        if normalized.hasPrefix("v1/") {
            return base.appendingPathComponent(normalized)
        }
        return base.appendingPathComponent("v1/" + normalized)
    }
}
