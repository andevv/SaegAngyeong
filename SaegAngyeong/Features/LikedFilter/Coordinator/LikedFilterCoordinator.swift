//
//  LikedFilterCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/1/26.
//

import UIKit

final class LikedFilterCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController

    init(dependency: AppDependency, navigationController: BaseNavigationController) {
        self.dependency = dependency
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = LikedFilterViewModel(
            filterRepository: dependency.filterRepository,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let viewController = LikedFilterViewController(viewModel: viewModel)
        viewController.onFilterSelected = { [weak self] filterID in
            self?.showFilterDetail(filterID: filterID)
        }
        navigationController.pushViewController(viewController, animated: true)
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
