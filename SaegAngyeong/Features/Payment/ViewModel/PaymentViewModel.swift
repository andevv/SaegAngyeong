//
//  PaymentViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import Foundation
import Combine

struct PaymentOrderInfo {
    let orderCode: String
    let amount: Int
    let title: String
}

final class PaymentViewModel: BaseViewModel, ViewModelType {

    private let filterID: String
    private let title: String
    private let totalPrice: Int
    private let orderRepository: OrderRepository
    private let paymentRepository: PaymentRepository

    init(
        filterID: String,
        title: String,
        totalPrice: Int,
        orderRepository: OrderRepository,
        paymentRepository: PaymentRepository
    ) {
        self.filterID = filterID
        self.title = title
        self.totalPrice = totalPrice
        self.orderRepository = orderRepository
        self.paymentRepository = paymentRepository
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let validatePayment: AnyPublisher<String, Never>
    }

    struct Output {
        let orderInfo: AnyPublisher<PaymentOrderInfo, Never>
        let paymentValidated: AnyPublisher<Void, Never>
    }

    func transform(input: Input) -> Output {
        let orderInfoSubject = CurrentValueSubject<PaymentOrderInfo?, Never>(nil)
        let paymentValidatedSubject = PassthroughSubject<Void, Never>()

        input.viewDidLoad
            .flatMap { [weak self] _ -> AnyPublisher<OrderCreate, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                guard self.totalPrice > 0 else {
                    self.error.send(DomainError.validation(message: "결제 금액이 올바르지 않습니다."))
                    return Empty().eraseToAnyPublisher()
                }
                self.isLoading.send(true)
                return self.orderRepository.create(filterID: self.filterID, totalPrice: self.totalPrice)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { [weak self] order in
                guard let self else { return }
                let info = PaymentOrderInfo(orderCode: order.code, amount: order.totalPrice, title: self.title)
                orderInfoSubject.send(info)
            }
            .store(in: &cancellables)

        input.validatePayment
            .flatMap { [weak self] impUID -> AnyPublisher<Void, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.paymentRepository.validatePayment(impUID: impUID, filterID: self.filterID)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { _ in
                paymentValidatedSubject.send(())
            }
            .store(in: &cancellables)

        return Output(
            orderInfo: orderInfoSubject.compactMap { $0 }.eraseToAnyPublisher(),
            paymentValidated: paymentValidatedSubject.eraseToAnyPublisher()
        )
    }
}
