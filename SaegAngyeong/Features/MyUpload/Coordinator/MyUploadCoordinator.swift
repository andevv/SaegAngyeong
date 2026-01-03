//
//  MyUploadCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/3/26.
//

import UIKit

final class MyUploadCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController
    private let userID: String

    init(dependency: AppDependency, navigationController: BaseNavigationController, userID: String) {
        self.dependency = dependency
        self.navigationController = navigationController
        self.userID = userID
    }

    func start() {
        let viewModel = MyUploadViewModel(
            filterRepository: dependency.filterRepository,
            userID: userID,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let viewController = MyUploadViewController(viewModel: viewModel)
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
