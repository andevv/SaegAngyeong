//
//  HomeCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 12/24/25.
//

import UIKit

final class HomeCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController

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
        navigationController.pushViewController(viewController, animated: true)
    }

    deinit {
        #if DEBUG
        print("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
