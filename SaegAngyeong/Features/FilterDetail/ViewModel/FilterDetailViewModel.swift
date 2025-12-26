//
//  FilterDetailViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/24/25.
//

import Foundation
import Combine
import UIKit
import CoreLocation

final class FilterDetailViewModel: BaseViewModel, ViewModelType {

    private let filterID: String
    private let filterRepository: FilterRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private let geocoder = CLGeocoder()

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
                let viewData = self.makeViewData(from: filter)
                detailSubject.send(viewData)
                self.resolveAddressIfNeeded(from: viewData, subject: detailSubject)
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
        let metadataLine1: String = {
            var parts: [String] = []
            if let lens = filter.photoMetadata?.lensInfo {
                parts.append("\(lens) -")
            }
            if let focal = filter.photoMetadata?.focalLength {
                parts.append("\(focal)mm")
            }
            if let aperture = filter.photoMetadata?.aperture {
                parts.append("𝒇\(aperture)")
            }
            if let iso = filter.photoMetadata?.iso {
                parts.append("ISO \(iso)")
            }
            return parts.joined(separator: " ")
        }()

        let metadataLine2 = {
            let resolution: String? = {
                guard let width = filter.photoMetadata?.pixelWidth,
                      let height = filter.photoMetadata?.pixelHeight
                else { return nil }
                let mp = Double(width * height) / 1_000_000.0
                let mpText = String(format: "%.0fMP", mp)
                return "\(mpText) · \(width) × \(height)"
            }()
            let fileSizeText: String? = {
                guard let bytes = filter.photoMetadata?.fileSize else { return nil }
                let mb = bytes / 1_000_000.0
                return String(format: "%.1fMB", mb)
            }()
            return [resolution, fileSizeText]
                .compactMap { $0 }
                .joined(separator: " · ")
        }()

        let metadataLine3: String = {
            if filter.photoMetadata?.latitude != nil, filter.photoMetadata?.longitude != nil {
                return "위치 확인 중"
            }
            return ""
        }()

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
            metadataLine1: metadataLine1,
            metadataLine2: metadataLine2,
            metadataLine3: metadataLine3,
            metadataFormat: filter.photoMetadata?.format ?? "EXIF",
            latitude: filter.photoMetadata?.latitude,
            longitude: filter.photoMetadata?.longitude,
            headers: imageHeaders
        )
    }

    private func resolveAddressIfNeeded(
        from viewData: FilterDetailViewData,
        subject: CurrentValueSubject<FilterDetailViewData?, Never>
    ) {
        guard let lat = viewData.latitude, let lon = viewData.longitude else { return }
        let location = CLLocation(latitude: lat, longitude: lon)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil, let placemark = placemarks?.first else { return }
            let address = [
                placemark.administrativeArea,
                placemark.locality,
                placemark.subLocality,
                placemark.thoroughfare,
                placemark.subThoroughfare
            ]
            .compactMap { $0 }
            .joined(separator: " ")
            guard !address.isEmpty else { return }
            DispatchQueue.main.async {
                subject.send(viewData.updating(metadataLine3: address))
            }
        }
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
    let metadataLine1: String
    let metadataLine2: String
    let metadataLine3: String
    let metadataFormat: String
    let latitude: Double?
    let longitude: Double?
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
            metadataLine1: metadataLine1,
            metadataLine2: metadataLine2,
            metadataLine3: metadataLine3,
            metadataFormat: metadataFormat,
            latitude: latitude,
            longitude: longitude,
            headers: headers
        )
    }

    func updating(metadataLine3: String) -> FilterDetailViewData {
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
            metadataLine1: metadataLine1,
            metadataLine2: metadataLine2,
            metadataLine3: metadataLine3,
            metadataFormat: metadataFormat,
            latitude: latitude,
            longitude: longitude,
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
