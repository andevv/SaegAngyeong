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
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        chatRepository: ChatRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.chatRepository = chatRepository
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
            .flatMap { [weak self] _ -> AnyPublisher<[ChatRoom], DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.chatRepository.fetchRooms()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { [weak self] rooms in
                guard let self else { return }
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy.MM.dd"
                let items = rooms.map { room in
                    let participant = room.participants.first
                    let title = participant?.name ?? participant?.nick ?? "알 수 없음"
                    let lastMessage: String
                    if let content = room.lastMessage?.content, content.isEmpty == false {
                        lastMessage = content
                    } else if let files = room.lastMessage?.fileURLs, files.isEmpty == false {
                        lastMessage = "사진을 보냈습니다."
                    } else {
                        lastMessage = "대화를 시작해보세요."
                    }
                    return MyChattingListItemViewData(
                        roomID: room.id,
                        title: title,
                        subtitle: room.lastMessage?.sender.nick ?? "-",
                        lastMessage: lastMessage,
                        updatedAtText: formatter.string(from: room.updatedAt),
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
    let subtitle: String
    let lastMessage: String
    let updatedAtText: String
    let profileImageURL: URL?
    let headers: [String: String]
}
