//
//  FeedCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import UIKit

final class FeedCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController

    init(dependency: AppDependency) {
        self.dependency = dependency
        self.navigationController = BaseNavigationController()
    }

    func start() -> UIViewController {
        let viewModel = FeedViewModel(
            filterRepository: dependency.filterRepository,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let viewController = FeedViewController(viewModel: viewModel)
        viewController.onFilterSelected = { [weak self] filterID in
            self?.showFilterDetail(filterID: filterID)
        }
        navigationController.setViewControllers([viewController], animated: false)
        return navigationController
    }

    private func showFilterDetail(filterID: String) {
        let viewModel = FilterDetailViewModel(
            filterID: filterID,
            filterRepository: dependency.filterRepository,
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
}
