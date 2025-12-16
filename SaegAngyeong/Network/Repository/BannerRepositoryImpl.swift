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
                    return Banner(
                        id: bannerDTO.name,
                        imageURL: imageURL ?? URL(string: "about:blank")!,
                        linkURL: nil,
                        title: bannerDTO.name,
                        description: nil
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
}
