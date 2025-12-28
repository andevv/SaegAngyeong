//
//  UserRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

final class UserRepositoryImpl: UserRepository {

    private let network: NetworkProviding

    init(network: NetworkProviding) {
        self.network = network
    }

    func validateEmail(_ email: String) -> AnyPublisher<Void, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func fetchProfile(userID: String) -> AnyPublisher<UserProfile, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func fetchMyProfile() -> AnyPublisher<UserProfile, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func updateMyProfile(_ profile: UserProfileUpdate) -> AnyPublisher<UserProfile, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func uploadProfileImage(data: Data, fileName: String, mimeType: String) -> AnyPublisher<URL, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func search(nick: String?) -> AnyPublisher<[UserSummary], DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func todayAuthor() -> AnyPublisher<TodayAuthor, DomainError> {
        network.request(TodayAuthorResponseDTO.self, endpoint: UserAPI.todayAuthor)
            .mapError { _ in DomainError.network }
            .map { dto in
                let base = URL(string: AppConfig.baseURL)
                let authorProfile = UserProfile(
                    id: dto.author.userID,
                    email: nil,
                    nick: dto.author.nick,
                    name: dto.author.name,
                    introduction: dto.author.introduction,
                    description: dto.author.description,
                    phoneNumber: nil,
                    profileImageURL: dto.author.profileImage.flatMap { path in
                        guard let base else { return nil }
                        let normalized = path.hasPrefix("/v1") ? path : "/v1" + path
                        return URL(string: normalized, relativeTo: base)
                    },
                    hashTags: dto.author.hashTags
                )

                let dateFormatter = ISO8601DateFormatter()
                let filters: [Filter] = dto.filters.map { item in
                    let urls = item.files.compactMap { path -> URL? in
                        guard let base else { return nil }
                        let normalized = path.hasPrefix("/v1") ? path : "/v1" + path
                        return URL(string: normalized, relativeTo: base)
                    }
                    let creator = UserSummary(
                        id: item.creator.userID,
                        nick: item.creator.nick,
                        profileImageURL: item.creator.profileImage.flatMap { path in
                            guard let base else { return nil }
                            let normalized = path.hasPrefix("/v1") ? path : "/v1" + path
                            return URL(string: normalized, relativeTo: base)
                        }
                    )

                    let created = dateFormatter.date(from: item.createdAt) ?? Date()
                    let updated = dateFormatter.date(from: item.updatedAt) ?? Date()

                    return Filter(
                        id: item.filterID,
                        category: item.category,
                        title: item.title,
                        introduction: item.description,
                        description: item.description,
                        files: urls,
                        price: 0,
                        filterValues: FilterValues(
                            brightness: nil, exposure: nil, contrast: nil, saturation: nil,
                            sharpness: nil, noiseReduction: nil, temperature: nil, highlight: nil, shadow: nil,
                            vignette: nil, grain: nil, blur: nil, fade: nil, blackPoint: nil
                        ),
                        photoMetadata: nil,
                        creator: creator,
                        createdAt: created,
                        updatedAt: updated,
                        comments: [],
                        isLiked: item.isLiked,
                        likeCount: item.likeCount,
                        buyerCount: item.buyerCount,
                        isDownloaded: false
                    )
                }

                return TodayAuthor(author: authorProfile, filters: filters)
            }
            .eraseToAnyPublisher()
    }
}
