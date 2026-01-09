//
//  StreamingListViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import Foundation
import Combine

final class StreamingListViewModel: BaseViewModel, ViewModelType {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
        let loadNext: AnyPublisher<Void, Never>
    }

    struct Output {
        let items: AnyPublisher<[StreamingListItemViewData], Never>
    }

    private let videoRepository: VideoRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private var nextCursor: String?
    private var isFetching = false

    init(
        videoRepository: VideoRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.videoRepository = videoRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        super.init()
    }

    func transform(input: Input) -> Output {
        let subject = CurrentValueSubject<[StreamingListItemViewData], Never>([])

        input.viewDidLoad
            .sink { [weak self] in
                self?.resetAndFetch(into: subject)
            }
            .store(in: &cancellables)

        input.refresh
            .sink { [weak self] in
                self?.resetAndFetch(into: subject)
            }
            .store(in: &cancellables)

        input.loadNext
            .sink { [weak self] in
                self?.fetchNext(into: subject)
            }
            .store(in: &cancellables)

        return Output(items: subject.eraseToAnyPublisher())
    }

    private func resetAndFetch(into subject: CurrentValueSubject<[StreamingListItemViewData], Never>) {
        nextCursor = nil
        fetchPage(cursor: nil, append: false, into: subject)
    }

    private func fetchNext(into subject: CurrentValueSubject<[StreamingListItemViewData], Never>) {
        guard let cursor = nextCursor, cursor.isEmpty == false else { return }
        fetchPage(cursor: cursor, append: true, into: subject)
    }

    private func fetchPage(
        cursor: String?,
        append: Bool,
        into subject: CurrentValueSubject<[StreamingListItemViewData], Never>
    ) {
        guard !isFetching else { return }
        isFetching = true
        isLoading.send(true)
        videoRepository.list(next: cursor, limit: 5)
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
                let mapped = paginated.items.map { self.mapItem(from: $0) }
                let updated = append ? subject.value + mapped : mapped
                subject.send(updated)
            }
            .store(in: &cancellables)
    }

    private func mapItem(from video: Video) -> StreamingListItemViewData {
        let duration = formatDuration(video.duration)
        return StreamingListItemViewData(
            id: video.id,
            title: video.title,
            description: video.description,
            durationText: duration,
            viewCountText: "조회수 \(video.viewCount)",
            likeCountText: "좋아요 \(video.likeCount)",
            thumbnailURL: video.thumbnailURL,
            headers: imageHeaders
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }

    private var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), token.isEmpty == false {
            headers["Authorization"] = token
        }
        return headers
    }
}

struct StreamingListItemViewData {
    let id: String
    let title: String
    let description: String
    let durationText: String
    let viewCountText: String
    let likeCountText: String
    let thumbnailURL: URL
    let headers: [String: String]
}
