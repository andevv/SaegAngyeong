//
//  FeedViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/21/25.
//

import Foundation
import Combine
import UIKit

final class FeedViewModel: BaseViewModel, ViewModelType {

    private let filterRepository: FilterRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private let defaultLimit = 10
    private let feedLimit = 20
    private var nextCursor: String?
    private var isFetchingFeed = false
    private var feedItems: [FeedItemViewData] = []

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
        let loadNextPage: AnyPublisher<Void, Never>
        let likeToggle: AnyPublisher<FeedLikeAction, Never>
    }

    struct Output {
        let rankings: AnyPublisher<[FeedRankViewData], Never>
        let selectedOrder: AnyPublisher<FeedOrder, Never>
        let feedItems: AnyPublisher<[FeedItemViewData], Never>
    }

    func transform(input: Input) -> Output {
        let rankingsSubject = PassthroughSubject<[FeedRankViewData], Never>()
        let orderSubject = CurrentValueSubject<FeedOrder, Never>(.popularity)
        let feedItemsSubject = CurrentValueSubject<[FeedItemViewData], Never>([])

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

        input.viewDidLoad
            .sink { [weak self] in
                guard let self else { return }
                self.resetFeed(order: orderSubject.value, subject: feedItemsSubject)
            }
            .store(in: &cancellables)

        input.orderSelection
            .sink { [weak self] order in
                guard let self else { return }
                self.resetFeed(order: order, subject: feedItemsSubject)
            }
            .store(in: &cancellables)

        input.loadNextPage
            .sink { [weak self] in
                guard let self else { return }
                self.fetchNextFeed(order: orderSubject.value, subject: feedItemsSubject)
            }
            .store(in: &cancellables)

        input.likeToggle
            .sink { [weak self] action in
                guard let self else { return }
                self.toggleLike(id: action.filterID, subject: feedItemsSubject)
            }
            .store(in: &cancellables)

        return Output(
            rankings: rankingsSubject.eraseToAnyPublisher(),
            selectedOrder: orderSubject.eraseToAnyPublisher(),
            feedItems: feedItemsSubject.eraseToAnyPublisher()
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

    private func resetFeed(order: FeedOrder, subject: CurrentValueSubject<[FeedItemViewData], Never>) {
        nextCursor = nil
        feedItems = []
        subject.send([])
        fetchFeed(order: order, next: nil, append: false, subject: subject)
    }

    private func fetchNextFeed(order: FeedOrder, subject: CurrentValueSubject<[FeedItemViewData], Never>) {
        guard let cursor = nextCursor, !cursor.isEmpty else { return }
        fetchFeed(order: order, next: cursor, append: true, subject: subject)
    }

    private func fetchFeed(
        order: FeedOrder,
        next: String?,
        append: Bool,
        subject: CurrentValueSubject<[FeedItemViewData], Never>
    ) {
        guard !isFetchingFeed else { return }
        isFetchingFeed = true
        filterRepository.list(
            next: next,
            limit: feedLimit,
            category: nil,
            orderBy: order.apiValue
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isFetchingFeed = false
            if case let .failure(error) = completion {
                self?.error.send(error)
            }
        } receiveValue: { [weak self] page in
            guard let self else { return }
            self.nextCursor = page.nextCursor
            let mapped = page.items.map { filter in
                FeedItemViewData(
                    id: filter.id,
                    title: filter.title,
                    creatorNick: filter.creator.nick,
                    category: filter.category,
                    description: filter.description,
                    imageURL: filter.files.first,
                    likeCount: filter.likeCount,
                    isLiked: filter.isLiked,
                    headers: self.imageHeaders
                )
            }
            if append {
                self.feedItems.append(contentsOf: mapped)
            } else {
                self.feedItems = mapped
            }
            subject.send(self.feedItems)
        }
        .store(in: &cancellables)
    }

    private func toggleLike(id: String, subject: CurrentValueSubject<[FeedItemViewData], Never>) {
        guard let index = feedItems.firstIndex(where: { $0.id == id }) else { return }
        let current = feedItems[index]
        let newStatus = !current.isLiked
        let delta = newStatus ? 1 : -1
        let newCount = max(0, current.likeCount + delta)
        feedItems[index] = current.updating(isLiked: newStatus, likeCount: newCount)
        subject.send(feedItems)

        filterRepository.like(id: id, status: newStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                if case let .failure(error) = completion {
                    self.error.send(error)
                    if let revertIndex = self.feedItems.firstIndex(where: { $0.id == id }) {
                        self.feedItems[revertIndex] = current
                        subject.send(self.feedItems)
                    }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
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

struct FeedItemViewData {
    let id: String
    let title: String
    let creatorNick: String
    let category: String
    let description: String
    let imageURL: URL?
    let likeCount: Int
    let isLiked: Bool
    let headers: [String: String]

    var masonryHeight: CGFloat {
        let seed = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let options: [CGFloat] = [180, 210, 240, 270]
        return options[seed % options.count]
    }

    func updating(isLiked: Bool, likeCount: Int) -> FeedItemViewData {
        FeedItemViewData(
            id: id,
            title: title,
            creatorNick: creatorNick,
            category: category,
            description: description,
            imageURL: imageURL,
            likeCount: likeCount,
            isLiked: isLiked,
            headers: headers
        )
    }
}

struct FeedLikeAction {
    let filterID: String
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
