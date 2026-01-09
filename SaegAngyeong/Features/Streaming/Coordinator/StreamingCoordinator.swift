//
//  StreamingCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import UIKit

final class StreamingCoordinator {
    private let navigationController: BaseNavigationController

    init(navigationController: BaseNavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        guard let url = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8") else { return }
        let viewModel = StreamingViewModel(streamURL: url)
        let viewController = StreamingViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    deinit {
        #if DEBUG
        print("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
