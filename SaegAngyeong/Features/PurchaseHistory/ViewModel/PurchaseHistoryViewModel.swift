//
//  PurchaseHistoryViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import Foundation
import Combine

struct PurchaseHistoryItemViewData {
    let orderCode: String
    let title: String
    let creator: String
    let priceText: String
    let paidAtText: String
    let thumbnailURL: URL?
}

final class PurchaseHistoryViewModel: BaseViewModel, ViewModelType {

    private let orderRepository: OrderRepository

    init(orderRepository: OrderRepository) {
        self.orderRepository = orderRepository
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
    }

    struct Output {
        let items: AnyPublisher<[PurchaseHistoryItemViewData], Never>
    }

    func transform(input: Input) -> Output {
        let itemsSubject = CurrentValueSubject<[PurchaseHistoryItemViewData], Never>([])

        Publishers.Merge(input.viewDidLoad, input.refresh)
            .flatMap { [weak self] _ -> AnyPublisher<[Order], DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.orderRepository.list()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { orders in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy.MM.dd"
                let items = orders.map { order in
                    let paidAt = order.paidAt.map { formatter.string(from: $0) } ?? "-"
                    return PurchaseHistoryItemViewData(
                        orderCode: order.code,
                        title: order.filter.title,
                        creator: order.filter.creator.nick,
                        priceText: "\(order.totalPrice) Coin",
                        paidAtText: paidAt,
                        thumbnailURL: order.filter.files.first
                    )
                }
                itemsSubject.send(items)
            }
            .store(in: &cancellables)

        return Output(items: itemsSubject.eraseToAnyPublisher())
    }
}
