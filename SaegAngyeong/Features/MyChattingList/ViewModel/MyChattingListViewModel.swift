//
//  MyChattingListViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 1/5/26.
//

import Foundation
import Combine

final class MyChattingListViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
    }

    struct Output {
        let items: AnyPublisher<[MyChattingListItemViewData], Never>
    }

    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private var currentUserID: String?

    init(
        chatRepository: ChatRepository,
        userRepository: UserRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.chatRepository = chatRepository
        self.userRepository = userRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        super.init()
    }

    var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), token.isEmpty == false {
            headers["Authorization"] = token
        }
        return headers
    }

    func transform(input: Input) -> Output {
        let itemsSubject = CurrentValueSubject<[MyChattingListItemViewData], Never>([])

        Publishers.Merge(input.viewDidLoad, input.refresh)
            .flatMap { [weak self] _ -> AnyPublisher<(String, [ChatRoom]), DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.userRepository.fetchMyProfile()
                    .map { $0.id }
                    .flatMap { [weak self] userID -> AnyPublisher<(String, [ChatRoom]), DomainError> in
                        guard let self else { return Empty().eraseToAnyPublisher() }
                        self.currentUserID = userID
                        return self.chatRepository.fetchRooms()
                            .map { (userID, $0) }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { [weak self] userID, rooms in
                guard let self else { return }
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.dateFormat = "a h:mm"
                let calendar = Calendar.current
                let items = rooms.map { room in
                    let participant = room.participants.first { $0.id != userID } ?? room.participants.first
                    let title = participant?.name ?? participant?.nick ?? "알 수 없음"
                    let lastMessage: String
                    if let content = room.lastMessage?.content, content.isEmpty == false {
                        lastMessage = content
                    } else if let files = room.lastMessage?.fileURLs, files.isEmpty == false {
                        lastMessage = "사진을 보냈습니다."
                    } else {
                        lastMessage = "대화를 시작해보세요."
                    }
                    let updatedAtText: String
                    if calendar.isDateInToday(room.updatedAt) {
                        updatedAtText = formatter.string(from: room.updatedAt)
                    } else if calendar.isDateInYesterday(room.updatedAt) {
                        updatedAtText = "어제"
                    } else {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy.MM.dd"
                        updatedAtText = dateFormatter.string(from: room.updatedAt)
                    }
                    return MyChattingListItemViewData(
                        roomID: room.id,
                        title: title,
                        lastMessage: lastMessage,
                        updatedAtText: updatedAtText,
                        profileImageURL: participant?.profileImageURL,
                        headers: self.imageHeaders
                    )
                }
                itemsSubject.send(items)
            }
            .store(in: &cancellables)

        return Output(items: itemsSubject.eraseToAnyPublisher())
    }
}

struct MyChattingListItemViewData {
    let roomID: String
    let title: String
    let lastMessage: String
    let updatedAtText: String
    let profileImageURL: URL?
    let headers: [String: String]
}
