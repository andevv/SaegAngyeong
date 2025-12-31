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
        Fail(error: DomainError.unknown(message: "Not implemented"))
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
}
