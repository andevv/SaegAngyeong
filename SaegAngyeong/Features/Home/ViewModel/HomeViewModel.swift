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
    private let userRepository: UserRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String

    init(
        filterRepository: FilterRepository,
        bannerRepository: BannerRepository,
        userRepository: UserRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.filterRepository = filterRepository
        self.bannerRepository = bannerRepository
        self.userRepository = userRepository
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
        let hotTrends: AnyPublisher<[HotTrendViewData], Never>
        let todayAuthor: AnyPublisher<TodayAuthorViewData, Never>
    }

    func transform(input: Input) -> Output {
        let highlightSubject = PassthroughSubject<HighlightViewData, Never>()
        let bannerSubject = PassthroughSubject<[BannerViewData], Never>()
        let categorySubject = CurrentValueSubject<[CategoryViewData], Never>(CategoryViewData.defaults)
        let hotTrendSubject = PassthroughSubject<[HotTrendViewData], Never>()
        let todayAuthorSubject = PassthroughSubject<TodayAuthorViewData, Never>()

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
                guard let self else { return }
                let viewData = banners.map { banner in
                    BannerViewData(
                        title: banner.title ?? "",
                        imageURL: banner.imageURL,
                        headers: self.imageHeaders,
                        linkURL: banner.linkURL,
                        payloadType: banner.payloadType
                    )
                }
                bannerSubject.send(viewData)
            }
            .store(in: &cancellables)

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<[Filter], DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                return self.filterRepository.hotTrend()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error.send(error)
                    self?.emitMockHotTrends(to: hotTrendSubject)
                }
            } receiveValue: { [weak self] filters in
                guard let self else { return }
                if filters.isEmpty {
                    self.emitMockHotTrends(to: hotTrendSubject)
                    return
                }
                let viewData = filters.map { filter in
                    HotTrendViewData(
                        id: filter.id,
                        title: filter.title,
                        likeCount: filter.likeCount,
                        imageURL: filter.files.first,
                        headers: self.imageHeaders
                    )
                }
                hotTrendSubject.send(viewData)
            }
            .store(in: &cancellables)

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<TodayAuthor, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                return self.userRepository.todayAuthor()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error.send(error)
                    self?.emitMockAuthor(to: todayAuthorSubject)
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }
                let viewData = TodayAuthorViewData(
                    name: result.author.name ?? "",
                    nick: result.author.nick,
                    introduction: result.author.introduction ?? "",
                    description: result.author.description ?? result.author.introduction ?? "",
                    profileImageURL: result.author.profileImageURL,
                    tags: result.author.hashTags,
                    filters: result.filters.compactMap { filter in
                        AuthorFilterViewData(
                            id: filter.id,
                            title: filter.title,
                            imageURL: filter.files.first,
                            headers: self.imageHeaders
                        )
                    },
                    headers: self.imageHeaders
                )
                todayAuthorSubject.send(viewData)
            }
            .store(in: &cancellables)

        return Output(
            highlight: highlightSubject.eraseToAnyPublisher(),
            banners: bannerSubject.eraseToAnyPublisher(),
            categories: categorySubject.eraseToAnyPublisher(),
            hotTrends: hotTrendSubject.eraseToAnyPublisher(),
            todayAuthor: todayAuthorSubject.eraseToAnyPublisher()
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
            headers: [:],
            linkURL: nil,
            payloadType: nil
        )
        subject.send([fallback])
    }

    private func emitMockHotTrends(to subject: PassthroughSubject<[HotTrendViewData], Never>) {
        let urls = [
            "https://images.unsplash.com/photo-1472214103451-9374bd1c798e",
            "https://images.unsplash.com/photo-1472220625704-91e1462799b2",
            "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429"
        ].compactMap { URL(string: $0) }

        let mocks = urls.enumerated().map { idx, url in
            HotTrendViewData(id: "mock-\(idx)", title: "트렌드 \(idx + 1)", likeCount: 120 + idx, imageURL: url, headers: [:])
        }
        subject.send(mocks)
    }

    private func emitMockAuthor(to subject: PassthroughSubject<TodayAuthorViewData, Never>) {
        let mockFilters = [
            AuthorFilterViewData(id: "mock1", title: "Mock1", imageURL: URL(string: "https://images.unsplash.com/photo-1473186578172-c141e6798cf4"), headers: [:]),
            AuthorFilterViewData(id: "mock2", title: "Mock2", imageURL: URL(string: "https://images.unsplash.com/photo-1433838552652-f9a46b332c40"), headers: [:]),
            AuthorFilterViewData(id: "mock3", title: "Mock3", imageURL: URL(string: "https://images.unsplash.com/photo-1469474968028-56623f02e42e"), headers: [:])
        ]
        let viewData = TodayAuthorViewData(
            name: "윤새싹",
            nick: "SESAC YOON",
            introduction: "자연의 섬세함을 담아내는 감성 사진작가",
            description: "자연의 섬세함을 담아내는 감성 사진작가",
            profileImageURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330"),
            tags: ["#섬세함", "#자연", "#미니멀"],
            filters: mockFilters,
            headers: [:]
        )
        subject.send(viewData)
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
    let linkURL: URL?
    let payloadType: String?
}

struct HotTrendViewData {
    let id: String
    let title: String
    let likeCount: Int
    let imageURL: URL?
    let headers: [String: String]
}

struct TodayAuthorViewData {
    let name: String
    let nick: String
    let introduction: String
    let description: String
    let profileImageURL: URL?
    let tags: [String]
    let filters: [AuthorFilterViewData]
    let headers: [String: String]
}

struct AuthorFilterViewData {
    let id: String
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

    var currentAccessToken: String? {
        accessTokenProvider()
    }
}
