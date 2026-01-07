//
//  HomeCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 12/24/25.
//

import UIKit
import Combine

final class HomeCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController
    private var cancellables = Set<AnyCancellable>()

    init(dependency: AppDependency) {
        self.dependency = dependency
        self.navigationController = BaseNavigationController()
    }

    func start() -> UIViewController {
        let viewModel = HomeViewModel(
            filterRepository: dependency.filterRepository,
            bannerRepository: dependency.bannerRepository,
            userRepository: dependency.userRepository,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let viewController = HomeViewController(viewModel: viewModel)
        viewController.onHotTrendSelected = { [weak self] filterID in
            self?.showFilterDetail(filterID: filterID)
        }
        viewController.onAuthorFilterSelected = { [weak self] filterID in
            self?.showFilterDetail(filterID: filterID)
        }
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }

    private func showFilterDetail(filterID: String) {
        let viewModel = FilterDetailViewModel(
            filterID: filterID,
            filterRepository: dependency.filterRepository,
            userRepository: dependency.userRepository,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let viewController = FilterDetailViewController(
            viewModel: viewModel,
            orderRepository: dependency.orderRepository,
            paymentRepository: dependency.paymentRepository
        )
        viewController.onMessageRequested = { [weak self] opponentID in
            self?.showChatRoom(opponentID: opponentID)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showChatRoom(opponentID: String) {
        dependency.chatRepository.createRoom(opponentID: opponentID)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] room in
                self?.showChatRoom(roomID: room.id)
            }
            .store(in: &cancellables)
    }

    private func showChatRoom(roomID: String) {
        guard let baseURL = URL(string: AppConfig.baseURL) else { return }
        let socketClient = ChatSocketClient(
            baseURL: baseURL,
            namespace: "/chats-\(roomID)",
            tokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken }
        )
        let viewModel = ChatRoomViewModel(
            context: .roomID(roomID),
            chatRepository: dependency.chatRepository,
            userRepository: dependency.userRepository,
            localStore: ChatLocalStore(),
            socketClient: socketClient
        )
        let viewController = ChatRoomViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    deinit {
        #if DEBUG
        print("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
