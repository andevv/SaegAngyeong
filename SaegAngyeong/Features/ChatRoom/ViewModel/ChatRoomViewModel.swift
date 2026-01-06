//
//  ChatRoomViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 1/6/26.
//

import Foundation
import Combine
import Realm
import RealmSwift

enum ChatRoomContext {
    case roomID(String)
    case opponentID(String)
}

final class ChatRoomViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
        let sendText: AnyPublisher<String, Never>
        let viewDidDisappear: AnyPublisher<Void, Never>
    }

    struct Output {
        let title: AnyPublisher<String, Never>
        let messages: AnyPublisher<[ChatMessageViewData], Never>
    }

    private let context: ChatRoomContext
    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private let localStore: ChatLocalStore
    private let socketClient: ChatSocketClient

    private var roomID: String?
    private var currentUserID: String?
    private var currentRoom: ChatRoom?
    private var isSyncing = false
    private var pendingMessages: [ChatMessage] = []
    private var messageToken: NotificationToken?

    init(
        context: ChatRoomContext,
        chatRepository: ChatRepository,
        userRepository: UserRepository,
        localStore: ChatLocalStore,
        socketClient: ChatSocketClient
    ) {
        self.context = context
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        self.localStore = localStore
        self.socketClient = socketClient
        super.init()
    }

    func transform(input: Input) -> Output {
        let titleSubject = CurrentValueSubject<String, Never>("채팅")
        let messagesSubject = CurrentValueSubject<[ChatMessageViewData], Never>([])

        input.viewDidLoad
            .sink { [weak self] in
                self?.bindLocalMessages(messagesSubject: messagesSubject)
                self?.fetchCurrentUserID(messagesSubject: messagesSubject)
                self?.prepareRoom(titleSubject: titleSubject, messagesSubject: messagesSubject)
            }
            .store(in: &cancellables)

        input.refresh
            .sink { [weak self] in
                self?.syncLatestMessages()
            }
            .store(in: &cancellables)

        input.sendText
            .sink { [weak self] text in
                self?.send(text: text)
            }
            .store(in: &cancellables)

        input.viewDidDisappear
            .sink { [weak self] in
                self?.socketClient.disconnect()
            }
            .store(in: &cancellables)

        return Output(
            title: titleSubject.eraseToAnyPublisher(),
            messages: messagesSubject.eraseToAnyPublisher()
        )
    }

    private func fetchCurrentUserID(messagesSubject: CurrentValueSubject<[ChatMessageViewData], Never>) {
        userRepository.fetchMyProfile()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { [weak self] profile in
                guard let self else { return }
                self.currentUserID = profile.id
                messagesSubject.send(self.mapToViewData(from: self.cachedMessages))
                if let room = self.currentRoom {
                    let title = self.makeTitle(from: room)
                    self.titleSubject?.send(title)
                }
            }
            .store(in: &cancellables)
    }

    private var cachedMessages: [ChatMessage] = []

    private func bindLocalMessages(messagesSubject: CurrentValueSubject<[ChatMessageViewData], Never>) {
        guard let roomID = roomID else { return }
        messageToken?.invalidate()
        messageToken = localStore.observeMessages(roomID: roomID) { [weak self] messages in
            guard let self else { return }
            self.cachedMessages = messages
            messagesSubject.send(self.mapToViewData(from: messages))
        }
    }

    private var titleSubject: CurrentValueSubject<String, Never>?

    private func prepareRoom(
        titleSubject: CurrentValueSubject<String, Never>,
        messagesSubject: CurrentValueSubject<[ChatMessageViewData], Never>
    ) {
        self.titleSubject = titleSubject
        resolveRoomID()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { [weak self] room in
                guard let self else { return }
                self.roomID = room.id
                self.currentRoom = room
                self.bindLocalMessages(messagesSubject: messagesSubject)
                titleSubject.send(self.makeTitle(from: room))
                self.connectSocket()
                self.syncLatestMessages()
            }
            .store(in: &cancellables)
    }

    private func resolveRoomID() -> AnyPublisher<ChatRoom, DomainError> {
        switch context {
        case .roomID(let id):
            return chatRepository.fetchRooms()
                .map { rooms in
                    rooms.first { $0.id == id } ?? ChatRoom(id: id, name: nil, participants: [], lastMessage: nil, createdAt: Date(), updatedAt: Date())
                }
                .eraseToAnyPublisher()
        case .opponentID(let opponentID):
            return chatRepository.createRoom(opponentID: opponentID)
        }
    }

    private func makeTitle(from room: ChatRoom) -> String {
        guard let me = currentUserID else {
            return room.participants.first?.name ?? room.participants.first?.nick ?? "채팅"
        }
        let opponent = room.participants.first { $0.id != me }
        return opponent?.name ?? opponent?.nick ?? "채팅"
    }

    private func syncLatestMessages() {
        guard let roomID else { return }
        isSyncing = true
        let cursor = localStore.lastMessageID(roomID: roomID)
        chatRepository.fetchMessages(roomID: roomID, next: cursor)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
                self?.isSyncing = false
                self?.flushPendingMessages()
            } receiveValue: { [weak self] page in
                self?.localStore.save(messages: page.items)
            }
            .store(in: &cancellables)
    }

    private func connectSocket() {
        guard let roomID else { return }
        socketClient.onMessage = { [weak self] dto in
            self?.handleIncoming(dto)
        }
        socketClient.connect()
        socketClient.join(roomID: roomID)
    }

    private func handleIncoming(_ dto: ChatMessageDTO) {
        let message = ChatMessage(
            id: dto.chatID,
            roomID: dto.roomID,
            sender: UserSummary(
                id: dto.sender.userID,
                nick: dto.sender.nick,
                profileImageURL: dto.sender.profileImage.flatMap { resolveURL(from: $0) },
                name: dto.sender.name,
                introduction: dto.sender.introduction,
                hashTags: dto.sender.hashTags
            ),
            content: dto.content,
            fileURLs: dto.files.compactMap { resolveURL(from: $0) },
            createdAt: ISO8601DateFormatter().date(from: dto.createdAt) ?? Date()
        )
        if localStore.contains(messageID: message.id) {
            return
        }
        if isSyncing {
            pendingMessages.append(message)
        } else {
            localStore.save(messages: [message])
        }
    }

    private func flushPendingMessages() {
        guard !pendingMessages.isEmpty else { return }
        let messages = pendingMessages
        pendingMessages.removeAll()
        localStore.save(messages: messages)
    }

    private func send(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let roomID else { return }
        socketClient.send(roomID: roomID, content: trimmed)
    }

    private func mapToViewData(from messages: [ChatMessage]) -> [ChatMessageViewData] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return messages.map { message in
            let isMine = message.sender.id == currentUserID
            let text: String
            if let content = message.content, !content.isEmpty {
                text = content
            } else if message.fileURLs.isEmpty == false {
                text = "사진을 보냈습니다."
            } else {
                text = ""
            }
            return ChatMessageViewData(
                id: message.id,
                text: text,
                timeText: formatter.string(from: message.createdAt),
                isMine: isMine,
                avatarURL: message.sender.profileImageURL
            )
        }
    }

    private func resolveURL(from path: String) -> URL? {
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

    deinit {
        messageToken?.invalidate()
        socketClient.disconnect()
    }
}

struct ChatMessageViewData {
    let id: String
    let text: String
    let timeText: String
    let isMine: Bool
    let avatarURL: URL?
}
