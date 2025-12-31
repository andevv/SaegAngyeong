//
//  MyPageViewModel.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import Foundation
import Combine

final class MyPageViewModel: BaseViewModel, ViewModelType {
    private let userRepository: UserRepository
    private let orderRepository: OrderRepository

    init(userRepository: UserRepository, orderRepository: OrderRepository) {
        self.userRepository = userRepository
        self.orderRepository = orderRepository
        super.init()
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let refresh: AnyPublisher<Void, Never>
    }

    struct Output {
        let profile: AnyPublisher<UserProfile?, Never>
    }

    func transform(input: Input) -> Output {
        let profileSubject = CurrentValueSubject<UserProfile?, Never>(nil)

        Publishers.Merge(input.viewDidLoad, input.refresh)
            .flatMap { [weak self] _ -> AnyPublisher<UserProfile, DomainError> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                self.isLoading.send(true)
                return self.userRepository.fetchMyProfile()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading.send(false)
                if case let .failure(error) = completion {
                    self?.error.send(error)
                }
            } receiveValue: { profile in
                profileSubject.send(profile)
            }
            .store(in: &cancellables)

        return Output(profile: profileSubject.eraseToAnyPublisher())
    }
}

extension MyPageViewModel {
    func makeEditViewModel(initialProfile: UserProfile?) -> MyPageEditViewModel {
        MyPageEditViewModel(userRepository: userRepository, initialProfile: initialProfile)
    }

    func makePurchaseHistoryViewModel() -> PurchaseHistoryViewModel {
        PurchaseHistoryViewModel(orderRepository: orderRepository)
    }
}
