//
//  LikedFilterViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import Foundation
import Combine

final class LikedFilterViewModel: BaseViewModel, ViewModelType {

    private let filterRepository: FilterRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private var nextCursor: String?
    private var isFetching = false

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
        let refresh: AnyPublisher<Void, Never>
        let loadNext: AnyPublisher<Void, Never>
    }

    struct Output {
        let items: AnyPublisher<[LikedFilterItemViewData], Never>
    }

    func transform(input: Input) -> Output {
        let itemsSubject = CurrentValueSubject<[LikedFilterItemViewData], Never>([])

        input.viewDidLoad
            .sink { [weak self] in
                self?.resetAndFetch(into: itemsSubject)
            }
            .store(in: &cancellables)

        input.refresh
            .sink { [weak self] in
                self?.resetAndFetch(into: itemsSubject)
            }
            .store(in: &cancellables)

        input.loadNext
            .sink { [weak self] in
                self?.fetchNext(into: itemsSubject)
            }
            .store(in: &cancellables)

        return Output(items: itemsSubject.eraseToAnyPublisher())
    }

    private func resetAndFetch(into subject: CurrentValueSubject<[LikedFilterItemViewData], Never>) {
        nextCursor = nil
        fetchPage(cursor: nil, append: false, into: subject)
    }

    private func fetchNext(into subject: CurrentValueSubject<[LikedFilterItemViewData], Never>) {
        guard let cursor = nextCursor, !cursor.isEmpty else { return }
        fetchPage(cursor: cursor, append: true, into: subject)
    }

    private func fetchPage(
        cursor: String?,
        append: Bool,
        into subject: CurrentValueSubject<[LikedFilterItemViewData], Never>
    ) {
        guard !isFetching else { return }
        isFetching = true
        isLoading.send(true)
        filterRepository.likedFilters(category: nil, next: cursor, limit: 10)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isFetching = false
                self.isLoading.send(false)
                if case let .failure(error) = completion {
                    self.error.send(error)
                }
            } receiveValue: { [weak self] paginated in
                guard let self else { return }
                self.nextCursor = paginated.nextCursor
                let mapped = paginated.items.map { filter in
                    LikedFilterItemViewData(
                        id: filter.id,
                        title: filter.title,
                        creator: filter.creator.nick,
                        likeCountText: "\(filter.likeCount)",
                        thumbnailURL: filter.files.first,
                        headers: self.imageHeaders
                    )
                }
                let updated = append ? subject.value + mapped : mapped
                subject.send(updated)
            }
            .store(in: &cancellables)
    }

    private var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), !token.isEmpty {
            headers["Authorization"] = token
        }
        return headers
    }
}
