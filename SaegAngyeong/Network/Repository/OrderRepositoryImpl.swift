//
//  OrderRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import Foundation
import Combine

final class OrderRepositoryImpl: OrderRepository {

    private let network: NetworkProviding

    init(network: NetworkProviding) {
        self.network = network
    }

    func create(filterID: String, totalPrice: Int) -> AnyPublisher<OrderCreate, DomainError> {
        let body = OrderCreateRequestDTO(filterID: filterID, totalPrice: totalPrice)
        return network.request(OrderCreateResponseDTO.self, endpoint: OrderAPI.create(body: body))
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else {
                    return OrderCreate(
                        id: dto.orderID,
                        code: dto.orderCode,
                        totalPrice: dto.totalPrice,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                }
                return OrderCreate(
                    id: dto.orderID,
                    code: dto.orderCode,
                    totalPrice: dto.totalPrice,
                    createdAt: self.parseISODate(dto.createdAt),
                    updatedAt: self.parseISODate(dto.updatedAt)
                )
            }
            .eraseToAnyPublisher()
    }

    func list() -> AnyPublisher<[Order], DomainError> {
        return network.request(OrderListResponseDTO.self, endpoint: OrderAPI.list)
            .mapError { _ in DomainError.network }
            .map { [weak self] dto in
                guard let self else { return [] }
                return dto.data.map { order in
                    let creator = UserSummary(
                        id: order.filter.creator.userID,
                        nick: order.filter.creator.nick,
                        profileImageURL: order.filter.creator.profileImage.flatMap { self.buildURL(from: $0) },
                        name: order.filter.creator.name,
                        introduction: order.filter.creator.introduction,
                        hashTags: order.filter.creator.hashTags ?? []
                    )
                    let files = order.filter.files.compactMap { self.buildURL(from: $0) }
                    let values = self.mapValues(order.filter.filterValues)
                    let totalPrice = order.totalPrice ?? order.filter.price
                    return Order(
                        id: order.orderID,
                        code: order.orderCode,
                        totalPrice: totalPrice,
                        filter: FilterSummary(
                            id: order.filter.filterID,
                            category: order.filter.category,
                            title: order.filter.title,
                            description: order.filter.description,
                            files: files,
                            price: order.filter.price,
                            creator: creator,
                            filterValues: values,
                            createdAt: self.parseISODate(order.filter.createdAt),
                            updatedAt: self.parseISODate(order.filter.updatedAt)
                        ),
                        paidAt: order.paidAt.map { self.parseISODate($0) },
                        createdAt: self.parseISODate(order.createdAt),
                        updatedAt: self.parseISODate(order.updatedAt)
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    func paymentDetail(orderCode: String) -> AnyPublisher<Order, DomainError> {
        Fail(error: DomainError.unknown(message: "Not implemented"))
            .eraseToAnyPublisher()
    }

    private func parseISODate(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value) ?? Date()
    }

    private func buildURL(from path: String) -> URL? {
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

    private func mapValues(_ values: FilterValuesDTO) -> FilterValues {
        FilterValues(
            brightness: values.brightness,
            exposure: values.exposure,
            contrast: values.contrast,
            saturation: values.saturation,
            sharpness: values.sharpness,
            noiseReduction: values.noiseReduction,
            temperature: values.temperature,
            highlight: values.highlights,
            shadow: values.shadows,
            vignette: values.vignette,
            grain: nil,
            blur: values.blur,
            fade: nil,
            blackPoint: values.blackPoint
        )
    }
}
