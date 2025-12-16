//
//  HomeViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

final class HomeViewModel: BaseViewModel, ViewModelType {

    private let filterRepository: FilterRepository
    private let bannerRepository: BannerRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        filterRepository: FilterRepository,
        bannerRepository: BannerRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.filterRepository = filterRepository
        self.bannerRepository = bannerRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
    }

    struct Output {
        let highlight: AnyPublisher<HighlightViewData, Never>
        let banners: AnyPublisher<[BannerViewData], Never>
        let categories: AnyPublisher<[CategoryViewData], Never>
    }

    func transform(input: Input) -> Output {
        let highlightSubject = PassthroughSubject<HighlightViewData, Never>()
        let bannerSubject = PassthroughSubject<[BannerViewData], Never>()
        let categorySubject = CurrentValueSubject<[CategoryViewData], Never>(CategoryViewData.defaults)

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<Filter, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.filterRepository.todayFilter()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                    self?.emitFallbackHighlight(to: highlightSubject)
                }
            } receiveValue: { filter in
                let viewData = HighlightViewData(
                    title: filter.title,
                    introduction: filter.introduction ?? "",
                    description: filter.description,
                    imageURL: filter.files.first,
                    headers: self.imageHeaders
                )
                highlightSubject.send(viewData)
            }
            .store(in: &cancellables)

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<[Banner], DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                return self.bannerRepository.mainBanners()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error.send(error)
                    self?.emitFallbackBanners(to: bannerSubject)
                }
            } receiveValue: { [weak self] banners in
                guard !banners.isEmpty else {
                    self?.emitFallbackBanners(to: bannerSubject)
                    return
                }
                let viewData = banners.map { banner in
                    BannerViewData(
                        title: banner.title ?? "",
                        imageURL: banner.imageURL,
                        headers: self?.imageHeaders ?? [:]
                    )
                }
                bannerSubject.send(viewData)
            }
            .store(in: &cancellables)

        return Output(
            highlight: highlightSubject.eraseToAnyPublisher(),
            banners: bannerSubject.eraseToAnyPublisher(),
            categories: categorySubject.eraseToAnyPublisher()
        )
    }

    private func emitFallbackHighlight(to subject: PassthroughSubject<HighlightViewData, Never>) {
        let viewData = HighlightViewData(
            title: "새싹을 담은 필터\n청록 새록",
            introduction: "오늘의 필터 소개",
            description: "햇살 아래 돋아나는 새싹처럼, 맑고 투명한 빛을 담은 자연 감성 필터입니다.",
            imageURL: nil,
            headers: [:]
        )
        subject.send(viewData)
    }

    private func emitFallbackBanners(to subject: PassthroughSubject<[BannerViewData], Never>) {
        let fallback = BannerViewData(
            title: "배너 준비 중",
            imageURL: nil,
            headers: [:]
        )
        subject.send([fallback])
    }
}

struct HighlightViewData {
    let title: String
    let introduction: String
    let description: String
    let imageURL: URL?
    let headers: [String: String]
}

struct BannerViewData {
    let title: String
    let imageURL: URL?
    let headers: [String: String]
}

struct CategoryViewData {
    let title: String
    let iconName: String

    static let defaults: [CategoryViewData] = [
        .init(title: "푸드", iconName: "Category_Food"),
        .init(title: "인물", iconName: "Category_People"),
        .init(title: "풍경", iconName: "Category_Landscape"),
        .init(title: "야경", iconName: "Category_Night"),
        .init(title: "별", iconName: "Category_Star")
    ]
}

extension HomeViewModel {
    var imageHeaders: [String: String] {
        var headers: [String: String] = ["SeSACKey": sesacKey]
        if let token = accessTokenProvider(), !token.isEmpty {
            headers["Authorization"] = token
        }
        return headers
    }
}
