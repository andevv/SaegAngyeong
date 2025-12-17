//
//  BannerRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 12/16/25.
//

import Foundation
import Combine

final class BannerRepositoryImpl: BannerRepository {

    private let network: NetworkProviding

    init(network: NetworkProviding) {
        self.network = network
    }

    func mainBanners() -> AnyPublisher<[Banner], DomainError> {
        network.request(BannerListResponseDTO.self, endpoint: BannerAPI.main)
            .mapError { _ in DomainError.network }
            .map { dto in
                return dto.data.compactMap { bannerDTO -> Banner in
                    let imageURL = Self.buildURL(from: bannerDTO.imageUrl)
                    let linkURL = Self.buildFullURL(from: bannerDTO.payload.value)
                    return Banner(
                        id: bannerDTO.name,
                        imageURL: imageURL ?? URL(string: "about:blank")!,
                        linkURL: linkURL,
                        title: bannerDTO.name,
                        description: nil,
                        payloadType: bannerDTO.payload.type
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    private static func buildURL(from path: String) -> URL? {
        guard let base = URL(string: AppConfig.baseURL) else { return nil }
        var normalized = path
        if normalized.hasPrefix("/") {
            normalized.removeFirst()
        }
        if !normalized.hasPrefix("v1/") {
            normalized = "v1/" + normalized
        }
        return base.appendingPathComponent(normalized)
    }

    private static func buildFullURL(from path: String) -> URL? {
        guard let base = URL(string: AppConfig.baseURL) else { return nil }
        if let url = URL(string: path), url.scheme != nil {
            return url
        }
        var normalized = path
        if normalized.hasPrefix("/") {
            normalized.removeFirst()
        }
        return base.appendingPathComponent(normalized)
    }
}
