//
//  VideoRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import Foundation
import Combine

final class VideoRepositoryImpl: VideoRepository {
    private let network: NetworkProviding

    init(network: NetworkProviding) {
        self.network = network
    }

    func list(next: String?, limit: Int?) -> AnyPublisher<Paginated<Video>, DomainError> {
        network.request(VideoListResponseDTO.self, endpoint: VideoAPI.list(next: next, limit: limit))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return Paginated(items: [], nextCursor: nil) }
                let items = dto.data.compactMap { self.mapVideo(from: $0) }
                let cursor = dto.nextCursor == "0" ? nil : dto.nextCursor
                return Paginated(items: items, nextCursor: cursor)
            }
            .eraseToAnyPublisher()
    }

    func streamInfo(videoID: String) -> AnyPublisher<StreamInfo, DomainError> {
        network.request(VideoStreamResponseDTO.self, endpoint: VideoAPI.stream(videoID: videoID))
            .tryMap { [weak self] dto in
                guard let self else { throw DomainError.decoding }
                guard let streamURL = self.buildURL(from: dto.streamURL) else {
                    throw DomainError.decoding
                }
                let qualities = dto.qualities?.compactMap { quality -> StreamQuality? in
                    guard let url = self.buildURL(from: quality.url) else { return nil }
                    return StreamQuality(label: quality.quality, url: url)
                } ?? []
                let subtitles = dto.subtitles?.compactMap { self.buildURL(from: $0.url) } ?? []
                return StreamInfo(videoID: dto.videoID, streamURL: streamURL, qualities: qualities, subtitles: subtitles)
            }
            .mapError { error in
                (error as? DomainError) ?? DomainError.network
            }
            .eraseToAnyPublisher()
    }

    func like(videoID: String, status: Bool) -> AnyPublisher<Void, DomainError> {
        let body = VideoLikeRequestDTO(likeStatus: status)
        return network.request(EmptyResponseDTO.self, endpoint: VideoAPI.like(videoID: videoID, body: body))
            .mapError { _ in DomainError.network }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

private extension VideoRepositoryImpl {
    func mapVideo(from dto: VideoDTO) -> Video? {
        guard let thumbnailURL = buildURL(from: dto.thumbnailURL) else { return nil }
        return Video(
            id: dto.videoID,
            fileName: dto.fileName,
            title: dto.title,
            description: dto.description,
            duration: dto.duration,
            thumbnailURL: thumbnailURL,
            availableQualities: dto.availableQualities,
            viewCount: dto.viewCount,
            likeCount: dto.likeCount,
            isLiked: dto.isLiked,
            createdAt: parseISODate(dto.createdAt)
        )
    }

    func parseISODate(_ value: String) -> Date {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        return formatter.date(from: value) ?? Date()
    }

    func buildURL(from path: String) -> URL? {
        if let url = URL(string: path), url.scheme != nil {
            return url
        }
        guard let base = URL(string: AppConfig.baseURL) else { return nil }
        var normalized = path
        if normalized.hasPrefix("/") {
            normalized.removeFirst()
        }
        let baseString = base.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if normalized.hasPrefix("v1/") {
            return URL(string: baseString + "/" + normalized)
        }
        return URL(string: baseString + "/v1/" + normalized)
    }
}
