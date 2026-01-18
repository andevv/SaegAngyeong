//
//  MyChattingListCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/6/26.
//

import UIKit

final class MyChattingListCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController
    private var chatRoomCoordinator: ChatRoomCoordinator?

    init(dependency: AppDependency, navigationController: BaseNavigationController) {
        self.dependency = dependency
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = MyChattingListViewModel(
            chatRepository: dependency.chatRepository,
            userRepository: dependency.userRepository,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let viewController = MyChattingListViewController(viewModel: viewModel)
        viewController.onRoomSelected = { [weak self] roomID in
            self?.showChatRoom(roomID: roomID)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    func routeToChatRoom(roomID: String) {
        showChatRoom(roomID: roomID)
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
        let coordinator = ChatRoomCoordinator(
            dependency: dependency,
            navigationController: navigationController
        )
        coordinator.bindPreview(to: viewController)
        chatRoomCoordinator = coordinator
        navigationController.pushViewController(viewController, animated: true)
    }

    deinit {
        #if DEBUG
        AppLogger.debug("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
