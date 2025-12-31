//
//  PaymentRepositoryImpl.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import Foundation
import Combine

final class PaymentRepositoryImpl: PaymentRepository {

    private let network: NetworkProviding

    init(network: NetworkProviding) {
        self.network = network
    }

    func validatePayment(impUID: String, filterID _: String) -> AnyPublisher<Void, DomainError> {
        let body = PaymentValidationRequestDTO(impUID: impUID)
        return network.request(ReceiptOrderResponseDTO.self, endpoint: PaymentAPI.validate(body: body))
            .mapError { _ in DomainError.network }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
