//
//  MainTabBarController.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit

final class MainTabBarController: UITabBarController {

    init(dependency: AppDependency) {
        super.init(nibName: nil, bundle: nil)
        setupTabs(dependency: dependency)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupTabs(dependency: AppDependency) {
        let homeVM = HomeViewModel(
            filterRepository: dependency.filterRepository,
            bannerRepository: dependency.bannerRepository,
            accessTokenProvider: { dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey
        )
        let homeVC = HomeViewController(viewModel: homeVM)

        let dummy1 = DummyViewController(titleText: "", named: "Feed_Fill", tag: 1, color: .systemGray6)
        let dummy2 = DummyViewController(titleText: "", named: "Filter_Fill", tag: 2, color: .systemGray5)
        let dummy3 = DummyViewController(titleText: "", named: "Search_Fill", tag: 3, color: .systemGray4)
        let dummy4 = DummyViewController(titleText: "", named: "Profile_Fill", tag: 4, color: .systemGray3)

        viewControllers = [
            homeVC,
            dummy1,
            dummy2,
            dummy3,
            dummy4
        ]
        selectedIndex = 0
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
