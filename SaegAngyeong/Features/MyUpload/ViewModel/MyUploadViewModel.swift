//
//  MyUploadViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 1/3/26.
//

import Foundation
import Combine

final class MyUploadViewModel: BaseViewModel, ViewModelType {

    private let filterRepository: FilterRepository
    private let userID: String
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private var nextCursor: String?
    private var isFetching = false

    init(
        filterRepository: FilterRepository,
        userID: String,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.filterRepository = filterRepository
        self.userID = userID
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
        let items: AnyPublisher<[MyUploadItemViewData], Never>
    }

    func transform(input: Input) -> Output {
        let itemsSubject = CurrentValueSubject<[MyUploadItemViewData], Never>([])

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

    private func resetAndFetch(into subject: CurrentValueSubject<[MyUploadItemViewData], Never>) {
        nextCursor = nil
        fetchPage(cursor: nil, append: false, into: subject)
    }

    private func fetchNext(into subject: CurrentValueSubject<[MyUploadItemViewData], Never>) {
        guard let cursor = nextCursor, !cursor.isEmpty else { return }
        fetchPage(cursor: cursor, append: true, into: subject)
    }

    private func fetchPage(
        cursor: String?,
        append: Bool,
        into subject: CurrentValueSubject<[MyUploadItemViewData], Never>
    ) {
        guard !isFetching else { return }
        isFetching = true
        isLoading.send(true)
        filterRepository.userFilters(userID: userID, next: cursor, limit: 10, category: nil)
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
                    MyUploadItemViewData(
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
