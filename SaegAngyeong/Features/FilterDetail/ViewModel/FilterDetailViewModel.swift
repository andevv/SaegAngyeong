//
//  FilterDetailViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/24/25.
//

import Foundation
import Combine
import UIKit

final class FilterDetailViewModel: BaseViewModel, ViewModelType {

    private let filterID: String
    private let filterRepository: FilterRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        filterID: String,
        filterRepository: FilterRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.filterID = filterID
        self.filterRepository = filterRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let likeToggle: AnyPublisher<Void, Never>
    }

    struct Output {
        let detail: AnyPublisher<FilterDetailViewData, Never>
    }

    func transform(input: Input) -> Output {
        let detailSubject = CurrentValueSubject<FilterDetailViewData?, Never>(nil)

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<Filter, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.filterRepository.detail(id: self.filterID)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { [weak self] filter in
                guard let self else { return }
                detailSubject.send(self.makeViewData(from: filter))
            }
            .store(in: &cancellables)

        input.likeToggle
            .compactMap { _ in detailSubject.value }
            .sink { [weak self] current in
                guard let self else { return }
                let newStatus = !current.isLiked
                let newCount = max(0, current.likeCount + (newStatus ? 1 : -1))
                let updated = current.updating(isLiked: newStatus, likeCount: newCount)
                detailSubject.send(updated)
                self.filterRepository.like(id: self.filterID, status: newStatus)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        if case let .failure(error) = completion {
                            self?.error.send(error)
                            detailSubject.send(current)
                        }
                    } receiveValue: { _ in }
                    .store(in: &self.cancellables)
            }
            .store(in: &cancellables)

        return Output(
            detail: detailSubject.compactMap { $0 }.eraseToAnyPublisher()
        )
    }

    private func makeViewData(from filter: Filter) -> FilterDetailViewData {
        let metadataTitle = filter.photoMetadata?.camera ?? "촬영 정보"
        let metadataDetail = [
            filter.photoMetadata?.lensInfo,
            filter.photoMetadata?.focalLength.map { "\($0)mm" },
            filter.photoMetadata?.aperture.map { "f\($0)" },
            filter.photoMetadata?.iso.map { "ISO \($0)" }
        ]
        .compactMap { $0 }
        .joined(separator: " · ")

        let sizeDetail = [
            filter.photoMetadata?.takenAt.map { ISO8601DateFormatter().string(from: $0) },
            filter.photoMetadata?.shutterSpeed
        ]
        .compactMap { $0 }
        .joined(separator: " · ")

        return FilterDetailViewData(
            title: filter.title,
            category: filter.category,
            description: filter.description,
            price: filter.price,
            likeCount: filter.likeCount,
            buyerCount: filter.buyerCount,
            isLiked: filter.isLiked,
            isDownloaded: filter.isDownloaded,
            originalImageURL: filter.files.first,
            filteredImageURL: filter.files.dropFirst().first,
            creatorName: filter.creator.nick,
            metadataTitle: metadataTitle,
            metadataDetail: metadataDetail,
            sizeDetail: sizeDetail,
            headers: imageHeaders
        )
    }
}

struct FilterDetailViewData {
    let title: String
    let category: String
    let description: String
    let price: Int
    let likeCount: Int
    let buyerCount: Int
    let isLiked: Bool
    let isDownloaded: Bool
    let originalImageURL: URL?
    let filteredImageURL: URL?
    let creatorName: String
    let metadataTitle: String
    let metadataDetail: String
    let sizeDetail: String
    let headers: [String: String]

    func updating(isLiked: Bool, likeCount: Int) -> FilterDetailViewData {
        FilterDetailViewData(
            title: title,
            category: category,
            description: description,
            price: price,
            likeCount: likeCount,
            buyerCount: buyerCount,
            isLiked: isLiked,
            isDownloaded: isDownloaded,
            originalImageURL: originalImageURL,
            filteredImageURL: filteredImageURL,
            creatorName: creatorName,
            metadataTitle: metadataTitle,
            metadataDetail: metadataDetail,
            sizeDetail: sizeDetail,
            headers: headers
        )
    }
}

extension FilterDetailViewModel {
    var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), !token.isEmpty {
            headers["Authorization"] = token
        }
        return headers
    }
}
