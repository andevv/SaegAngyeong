//
//  MyPageCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/1/26.
//

import UIKit

final class MyPageCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController
    private var likedFilterCoordinator: LikedFilterCoordinator?
    private var myUploadCoordinator: MyUploadCoordinator?

    init(dependency: AppDependency) {
        self.dependency = dependency
        self.navigationController = BaseNavigationController()
    }

    func start() -> UIViewController {
        let viewModel = MyPageViewModel(
            authRepository: dependency.authRepository,
            userRepository: dependency.userRepository,
            orderRepository: dependency.orderRepository,
            filterRepository: dependency.filterRepository,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let viewController = MyPageViewController(viewModel: viewModel)
        viewController.onEditProfileRequested = { [weak self, weak viewModel] profile in
            guard let self, let viewModel else { return }
            let editVM = viewModel.makeEditViewModel(initialProfile: profile)
            let editVC = MyPageEditViewController(viewModel: editVM)
            self.navigationController.pushViewController(editVC, animated: true)
        }
        viewController.onPurchaseHistoryRequested = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            let historyVC = PurchaseHistoryViewController(viewModel: viewModel.makePurchaseHistoryViewModel())
            self.navigationController.pushViewController(historyVC, animated: true)
        }
        viewController.onLikedFilterRequested = { [weak self, weak viewModel] in
            guard let self else { return }
            let coordinator = LikedFilterCoordinator(
                dependency: self.dependency,
                navigationController: self.navigationController
            )
            self.likedFilterCoordinator = coordinator
            coordinator.start()
        }
        viewController.onMyUploadRequested = { [weak self, weak viewModel] userID in
            guard let self else { return }
            let coordinator = MyUploadCoordinator(
                dependency: self.dependency,
                navigationController: self.navigationController,
                userID: userID
            )
            self.myUploadCoordinator = coordinator
            coordinator.start()
        }
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }

    deinit {
        #if DEBUG
        print("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
