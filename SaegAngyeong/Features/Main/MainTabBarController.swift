//
//  MainTabBarController.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit

final class MainTabBarController: UITabBarController {

    private let homeCoordinator: HomeCoordinator

    init(dependency: AppDependency) {
        self.homeCoordinator = HomeCoordinator(dependency: dependency)
        super.init(nibName: nil, bundle: nil)
        configureAppearance()
        setupTabs(dependency: dependency)
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func configureAppearance() {
        tabBar.tintColor = .gray15
        tabBar.unselectedItemTintColor = .gray45
    }

    override var childForStatusBarStyle: UIViewController? {
        selectedViewController
    }

    private func setupTabs(dependency: AppDependency) {
        let homeVC = homeCoordinator.start()

        let feedVM = FeedViewModel(
            filterRepository: dependency.filterRepository,
            accessTokenProvider: { dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let feedVC = FeedViewController(viewModel: feedVM)
        let feedNav = BaseNavigationController(rootViewController: feedVC)

        let filterMakeVM = FilterMakeViewModel(filterRepository: dependency.filterRepository)
        let filterMakeVC = FilterMakeViewController(viewModel: filterMakeVM)
        let filterMakeNav = BaseNavigationController(rootViewController: filterMakeVC)

        let dummy3 = DummyViewController(titleText: "", named: "Search_Empty", tag: 3, color: .systemGray4)
        let dummy4 = DummyViewController(titleText: "", named: "Profile_Empty", tag: 4, color: .systemGray3)

        viewControllers = [
            homeVC,
            feedNav,
            filterMakeNav,
            dummy3,
            dummy4
        ]
        selectedIndex = 0
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - Dummy ViewController

private final class DummyViewController: UIViewController {
    init(titleText: String, named: String, tag: Int, color: UIColor) {
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(title: titleText, image: UIImage(named: named), tag: tag)
        view.backgroundColor = color
        self.title = titleText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
