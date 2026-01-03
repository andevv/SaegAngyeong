//
//  FilterRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Combine

final class FilterRepositoryImpl: FilterRepository {

    private let network: NetworkProviding

    init(network: NetworkProviding) {
        self.network = network
    }

    func uploadFiles(_ files: [UploadFileData]) -> AnyPublisher<[URL], DomainError> {
        let uploadFiles = files.map { UploadFile(data: $0.data, fileName: $0.fileName, mimeType: $0.mimeType) }
        return network.request(FilterFileUploadResponseDTO.self, endpoint: FilterAPI.uploadFiles(files: uploadFiles))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return [] }
                return dto.files.compactMap { self.buildURL(from: $0) }
            }
            .eraseToAnyPublisher()
    }

    func create(_ draft: FilterDraft) -> AnyPublisher<Filter, DomainError> {
        let request = FilterCreateRequestDTO(
            category: draft.category,
            title: draft.title,
            price: draft.price,
            description: draft.description,
            files: draft.files,
            photoMetadata: draft.photoMetadata.map { meta in
                PhotoMetadataRequestDTO(
                    camera: meta.camera,
                    lensInfo: meta.lensInfo,
                    focalLength: meta.focalLength,
                    aperture: meta.aperture,
                    iso: meta.iso,
                    shutterSpeed: meta.shutterSpeed,
                    pixelWidth: meta.pixelWidth,
                    pixelHeight: meta.pixelHeight,
                    fileSize: meta.fileSize,
                    format: meta.format,
                    dateTimeOriginal: meta.takenAt.map { self.formatISODate($0) },
                    latitude: meta.latitude,
                    longitude: meta.longitude
                )
            },
            filterValues: FilterValuesRequestDTO(
                brightness: draft.filterValues.brightness ?? 0,
                exposure: draft.filterValues.exposure ?? 0,
                contrast: draft.filterValues.contrast ?? 0,
                saturation: draft.filterValues.saturation ?? 0,
                sharpness: draft.filterValues.sharpness ?? 0,
                blur: draft.filterValues.blur ?? 0,
                vignette: draft.filterValues.vignette ?? 0,
                noiseReduction: draft.filterValues.noiseReduction ?? 0,
                highlights: draft.filterValues.highlight ?? 0,
                shadows: draft.filterValues.shadow ?? 0,
                temperature: draft.filterValues.temperature ?? 0,
                blackPoint: draft.filterValues.blackPoint ?? 0
            )
        )
        return network.request(FilterDetailResponseDTO.self, endpoint: FilterAPI.create(body: request))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else {
                    return Filter(
                        id: dto.filterID,
                        category: dto.category,
                        title: dto.title,
                        introduction: dto.description,
                        description: dto.description,
                        files: [],
                        price: dto.price,
                        filterValues: FilterValues(
                            brightness: nil, exposure: nil, contrast: nil, saturation: nil,
                            sharpness: nil, noiseReduction: nil, temperature: nil, highlight: nil, shadow: nil,
                            vignette: nil, grain: nil, blur: nil, fade: nil, blackPoint: nil
                        ),
                        photoMetadata: nil,
                        creator: UserSummary(id: dto.creator.userID, nick: dto.creator.nick, profileImageURL: nil, name: dto.creator.name, introduction: dto.creator.introduction, hashTags: dto.creator.hashTags ?? []),
                        createdAt: Date(),
                        updatedAt: Date(),
                        comments: [],
                        isLiked: dto.isLiked,
                        likeCount: dto.likeCount,
                        buyerCount: dto.buyerCount,
                        isDownloaded: dto.isDownloaded
                    )
                }
                return self.mapFilter(from: dto)
            }
            .eraseToAnyPublisher()
    }

    func list(next: String?, limit: Int?, category: String?, orderBy: String?) -> AnyPublisher<Paginated<Filter>, DomainError> {
        network.request(FilterSummaryPaginationResponseDTO.self, endpoint: FilterAPI.list(next: next, limit: limit, category: category, orderBy: orderBy))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return Paginated(items: [], nextCursor: nil) }
                let items = dto.data.map { item -> Filter in
                    let urls = item.files.compactMap { self.buildURL(from: $0) }
                    let creator = UserSummary(
                        id: item.creator.userID,
                        nick: item.creator.nick,
                        profileImageURL: item.creator.profileImage.flatMap { self.buildURL(from: $0) },
                        name: item.creator.name,
                        introduction: item.creator.introduction,
                        hashTags: item.creator.hashTags ?? []
                    )
                    let created = self.parseISODate(item.createdAt)
                    let updated = self.parseISODate(item.updatedAt)
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
                let cursor = dto.nextCursor == "0" ? nil : dto.nextCursor
                return Paginated(items: items, nextCursor: cursor)
            }
            .eraseToAnyPublisher()
    }

    func detail(id: String) -> AnyPublisher<Filter, DomainError> {
        network.request(FilterDetailResponseDTO.self, endpoint: FilterAPI.detail(id: id))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else {
                    return Filter(
                        id: dto.filterID,
                        category: dto.category,
                        title: dto.title,
                        introduction: dto.description,
                        description: dto.description,
                        files: [],
                        price: dto.price,
                        filterValues: FilterValues(
                            brightness: nil, exposure: nil, contrast: nil, saturation: nil,
                            sharpness: nil, noiseReduction: nil, temperature: nil, highlight: nil, shadow: nil,
                            vignette: nil, grain: nil, blur: nil, fade: nil, blackPoint: nil
                        ),
                        photoMetadata: nil,
                        creator: UserSummary(id: dto.creator.userID, nick: dto.creator.nick, profileImageURL: nil, name: dto.creator.name, introduction: dto.creator.introduction, hashTags: dto.creator.hashTags ?? []),
                        createdAt: Date(),
                        updatedAt: Date(),
                        comments: [],
                        isLiked: dto.isLiked,
                        likeCount: dto.likeCount,
                        buyerCount: dto.buyerCount,
                        isDownloaded: dto.isDownloaded
                    )
                }
                return self.mapFilter(from: dto)
            }
            .eraseToAnyPublisher()
    }

    func update(id: String, draft: FilterDraft) -> AnyPublisher<Filter, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func delete(id: String) -> AnyPublisher<Void, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func like(id: String, status: Bool) -> AnyPublisher<Void, DomainError> {
        let body = FilterLikeRequestDTO(likeStatus: status)
        return network.request(FilterLikeResponseDTO.self, endpoint: FilterAPI.like(filterID: id, body: body))
            .mapError { _ in DomainError.network }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func userFilters(userID: String, next: String?, limit: Int?, category: String?) -> AnyPublisher<Paginated<Filter>, DomainError> {
        network.request(FilterSummaryPaginationResponseDTO.self, endpoint: FilterAPI.userFilters(userID: userID, next: next, limit: limit, category: category))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return Paginated(items: [], nextCursor: nil) }
                let items = dto.data.map { item -> Filter in
                    let urls = item.files.compactMap { self.buildURL(from: $0) }
                    let creator = UserSummary(
                        id: item.creator.userID,
                        nick: item.creator.nick,
                        profileImageURL: item.creator.profileImage.flatMap { self.buildURL(from: $0) },
                        name: item.creator.name,
                        introduction: item.creator.introduction,
                        hashTags: item.creator.hashTags ?? []
                    )
                    let created = self.parseISODate(item.createdAt)
                    let updated = self.parseISODate(item.updatedAt)
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
                let cursor = dto.nextCursor == "0" ? nil : dto.nextCursor
                return Paginated(items: items, nextCursor: cursor)
            }
            .eraseToAnyPublisher()
    }

    func likedFilters(category: String?, next: String?, limit: Int?) -> AnyPublisher<Paginated<Filter>, DomainError> {
        network.request(FilterSummaryPaginationResponseDTO.self, endpoint: FilterAPI.likedFilters(category: category, next: next, limit: limit))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return Paginated(items: [], nextCursor: nil) }
                let items = dto.data.map { item -> Filter in
                    let urls = item.files.compactMap { self.buildURL(from: $0) }
                    let creator = UserSummary(
                        id: item.creator.userID,
                        nick: item.creator.nick,
                        profileImageURL: item.creator.profileImage.flatMap { self.buildURL(from: $0) },
                        name: item.creator.name,
                        introduction: item.creator.introduction,
                        hashTags: item.creator.hashTags ?? []
                    )
                    let created = self.parseISODate(item.createdAt)
                    let updated = self.parseISODate(item.updatedAt)
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
                let cursor = dto.nextCursor == "0" ? nil : dto.nextCursor
                return Paginated(items: items, nextCursor: cursor)
            }
            .eraseToAnyPublisher()
    }

    func hotTrend() -> AnyPublisher<[Filter], DomainError> {
        network.request(HotTrendResponseDTO.self, endpoint: FilterAPI.hotTrend)
            .mapError { _ in DomainError.network }
            .map { dto -> [Filter] in
                let base = URL(string: AppConfig.baseURL)
                return dto.data.map { item in
                    let urls = item.files.compactMap { path -> URL? in
                        guard let base else { return nil }
                        let normalized = path.hasPrefix("/v1") ? path : "/v1" + path
                        return URL(string: normalized, relativeTo: base)
                    }
                    let creator = UserSummary(id: "", nick: "", profileImageURL: nil, name: nil, introduction: nil, hashTags: [])
                    let filterValues = FilterValues(
                        brightness: nil, exposure: nil, contrast: nil, saturation: nil,
                        sharpness: nil, noiseReduction: nil, temperature: nil, highlight: nil, shadow: nil,
                        vignette: nil, grain: nil, blur: nil, fade: nil, blackPoint: nil
                    )
                    let now = Date()
                    return Filter(
                        id: item.id,
                        category: item.category ?? "",
                        title: item.title,
                        introduction: item.description ?? "",
                        description: item.description ?? "",
                        files: urls,
                        price: 0,
                        filterValues: filterValues,
                        photoMetadata: nil,
                        creator: creator,
                        createdAt: now,
                        updatedAt: now,
                        comments: [],
                        isLiked: item.isLiked ?? false,
                        likeCount: item.likeCount,
                        buyerCount: item.buyerCount ?? 0,
                        isDownloaded: false
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    func todayFilter() -> AnyPublisher<Filter, DomainError> {
        network.request(TodayFilterResponseDTO.self, endpoint: FilterAPI.todayFilter)
            .mapError { _ in DomainError.network }
            .map { dto -> Filter in
                let base = URL(string: AppConfig.baseURL)
                let urls = dto.files.compactMap { path -> URL? in
                    guard let base else { return nil }
                    let normalized = path.hasPrefix("/v1") ? path : "/v1" + path
                    return URL(string: normalized, relativeTo: base)
                }
                let creator = UserSummary(id: "", nick: "", profileImageURL: nil, name: nil, introduction: nil, hashTags: [])
                let filterValues = FilterValues(
                    brightness: nil, exposure: nil, contrast: nil, saturation: nil,
                    sharpness: nil, noiseReduction: nil, temperature: nil, highlight: nil, shadow: nil,
                    vignette: nil, grain: nil, blur: nil, fade: nil, blackPoint: nil
                )
                let dateFormatter = ISO8601DateFormatter()
                let created = dateFormatter.date(from: dto.createdAt) ?? Date()
                let updated = dateFormatter.date(from: dto.updatedAt) ?? Date()

                return Filter(
                    id: dto.filterID,
                    category: "",
                    title: dto.title,
                    introduction: dto.introduction,
                    description: dto.description,
                    files: urls,
                    price: 0,
                    filterValues: filterValues,
                    photoMetadata: nil,
                    creator: creator,
                    createdAt: created,
                    updatedAt: updated,
                    comments: [],
                    isLiked: false,
                    likeCount: 0,
                    buyerCount: 0,
                    isDownloaded: false
                )
            }
            .eraseToAnyPublisher()
    }

    func addComment(filterID: String, draft: CommentDraft) -> AnyPublisher<Comment, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func updateComment(filterID: String, commentID: String, content: String) -> AnyPublisher<Comment, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }

    func deleteComment(filterID: String, commentID: String) -> AnyPublisher<Void, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented")).eraseToAnyPublisher()
    }
}

private extension FilterRepositoryImpl {
    func mapFilter(from dto: FilterDetailResponseDTO) -> Filter {
        let urls = dto.files.compactMap { self.buildURL(from: $0) }
        let creator = UserSummary(
            id: dto.creator.userID,
            nick: dto.creator.nick,
            profileImageURL: dto.creator.profileImage.flatMap { self.buildURL(from: $0) },
            name: dto.creator.name,
            introduction: dto.creator.introduction,
            hashTags: dto.creator.hashTags ?? []
        )
        let created = self.parseISODate(dto.createdAt)
        let updated = self.parseISODate(dto.updatedAt)
        let values = FilterValues(
            brightness: dto.filterValues?.brightness,
            exposure: dto.filterValues?.exposure,
            contrast: dto.filterValues?.contrast,
            saturation: dto.filterValues?.saturation,
            sharpness: dto.filterValues?.sharpness,
            noiseReduction: dto.filterValues?.noiseReduction,
            temperature: dto.filterValues?.temperature,
            highlight: dto.filterValues?.highlights,
            shadow: dto.filterValues?.shadows,
            vignette: dto.filterValues?.vignette,
            grain: nil,
            blur: dto.filterValues?.blur,
            fade: nil,
            blackPoint: dto.filterValues?.blackPoint
        )
        let photo = dto.photoMetadata.map { meta in
            PhotoMetadata(
                camera: meta.camera,
                lensInfo: meta.lensInfo,
                focalLength: meta.focalLength,
                aperture: meta.aperture,
                shutterSpeed: meta.shutterSpeed,
                iso: meta.iso,
                pixelWidth: meta.pixelWidth,
                pixelHeight: meta.pixelHeight,
                fileSize: meta.fileSize,
                format: meta.format,
                whiteBalance: nil,
                location: nil,
                takenAt: meta.dateTimeOriginal.map { self.parseISODate($0) },
                latitude: meta.latitude,
                longitude: meta.longitude
            )
        }
        return Filter(
            id: dto.filterID,
            category: dto.category,
            title: dto.title,
            introduction: dto.description,
            description: dto.description,
            files: urls,
            price: dto.price,
            filterValues: values,
            photoMetadata: photo,
            creator: creator,
            createdAt: created,
            updatedAt: updated,
            comments: [],
            isLiked: dto.isLiked,
            likeCount: dto.likeCount,
            buyerCount: dto.buyerCount,
            isDownloaded: dto.isDownloaded
        )
    }

    func buildURL(from path: String) -> URL? {
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

    func parseISODate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value) ?? Date()
    }

    func formatISODate(_ value: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: value)
    }
}
