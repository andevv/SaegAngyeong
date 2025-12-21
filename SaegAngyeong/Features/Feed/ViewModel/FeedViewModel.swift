//
//  FeedViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/21/25.
//

import Foundation
import Combine

final class FeedViewModel: BaseViewModel, ViewModelType {

    private let filterRepository: FilterRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private let defaultLimit = 10

    init(
        filterRepository: FilterRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.filterRepository = filterRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let orderSelection: AnyPublisher<FeedOrder, Never>
    }

    struct Output {
        let rankings: AnyPublisher<[FeedRankViewData], Never>
        let selectedOrder: AnyPublisher<FeedOrder, Never>
    }

    func transform(input: Input) -> Output {
        let rankingsSubject = PassthroughSubject<[FeedRankViewData], Never>()
        let orderSubject = CurrentValueSubject<FeedOrder, Never>(.popularity)

        let load = input.viewDidLoad
            .map { orderSubject.value }

        let orderChange = input.orderSelection
            .handleEvents(receiveOutput: { orderSubject.send($0) })

        Publishers.Merge(load, orderChange)
            .flatMap { [weak self] order -> AnyPublisher<Paginated<Filter>, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.filterRepository.list(
                    next: nil,
                    limit: self.defaultLimit,
                    category: nil,
                    orderBy: order.apiValue
                )
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                    self?.emitMockRankings(to: rankingsSubject)
                }
            } receiveValue: { [weak self] page in
                guard let self else { return }
                let viewData = page.items.enumerated().map { idx, filter in
                    FeedRankViewData(
                        id: filter.id,
                        title: filter.title,
                        creatorNick: filter.creator.nick,
                        category: filter.category,
                        imageURL: filter.files.first,
                        headers: self.imageHeaders,
                        rank: idx + 1,
                        likeCount: filter.likeCount,
                        buyerCount: filter.buyerCount
                    )
                }
                if viewData.isEmpty {
                    self.emitMockRankings(to: rankingsSubject)
                } else {
                    rankingsSubject.send(viewData)
                }
            }
            .store(in: &cancellables)

        return Output(
            rankings: rankingsSubject.eraseToAnyPublisher(),
            selectedOrder: orderSubject.eraseToAnyPublisher()
        )
    }

    private func emitMockRankings(to subject: PassthroughSubject<[FeedRankViewData], Never>) {
        let mocks: [FeedRankViewData] = [
            FeedRankViewData(id: "mock1", title: "청록 새록", creatorNick: "YOON SESAC", category: "인물", imageURL: nil, headers: [:], rank: 1, likeCount: 120, buyerCount: 32),
            FeedRankViewData(id: "mock2", title: "밤의 숨결", creatorNick: "MULGYEOL", category: "야경", imageURL: nil, headers: [:], rank: 2, likeCount: 98, buyerCount: 20),
            FeedRankViewData(id: "mock3", title: "포근한 오후", creatorNick: "SAEGAK", category: "풍경", imageURL: nil, headers: [:], rank: 3, likeCount: 76, buyerCount: 12)
        ]
        subject.send(mocks)
    }
}

enum FeedOrder: CaseIterable {
    case popularity
    case purchase
    case latest

    var title: String {
        switch self {
        case .popularity: return "인기순"
        case .purchase: return "구매순"
        case .latest: return "최신순"
        }
    }

    var apiValue: String {
        switch self {
        case .popularity: return "popularity"
        case .purchase: return "purchase"
        case .latest: return "latest"
        }
    }
}

struct FeedRankViewData {
    let id: String
    let title: String
    let creatorNick: String
    let category: String
    let imageURL: URL?
    let headers: [String: String]
    let rank: Int
    let likeCount: Int
    let buyerCount: Int
}

extension FeedViewModel {
    var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), !token.isEmpty {
            headers["Authorization"] = token
        }
        return headers
    }

    var currentAccessToken: String? {
        accessTokenProvider()
    }
}
