//
//  HomeViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit

final class HomeViewController: BaseViewController<HomeViewModel> {

    override init(viewModel: HomeViewModel) {
        super.init(viewModel: viewModel)
        tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "Home_Empty"),
            selectedImage: UIImage(named: "Home_Fill")
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
