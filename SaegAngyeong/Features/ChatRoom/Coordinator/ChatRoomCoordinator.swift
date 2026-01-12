//
//  ChatRoomCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/12/26.
//

import UIKit

final class ChatRoomCoordinator {
    private let dependency: AppDependency
    private let navigationController: BaseNavigationController

    init(dependency: AppDependency, navigationController: BaseNavigationController) {
        self.dependency = dependency
        self.navigationController = navigationController
    }

    func bindPreview(to viewController: ChatRoomViewController) {
        viewController.onImagePreview = { [weak self] urls, startIndex in
            self?.showImagePreview(urls: urls, startIndex: startIndex)
        }
    }

    private func showImagePreview(urls: [URL], startIndex: Int) {
        guard urls.isEmpty == false else { return }
        let previewVC = ChatRoomImagePreviewViewController(
            urls: urls,
            startIndex: startIndex,
            headers: makeImageHeaders()
        )
        previewVC.modalPresentationStyle = .fullScreen
        previewVC.modalTransitionStyle = .crossDissolve
        navigationController.present(previewVC, animated: true)
    }

    private func makeImageHeaders() -> [String: String] {
        var headers: [String: String] = ["SeSACKey": AppConfig.apiKey]
        if let token = dependency.tokenStore.accessToken {
            headers["Authorization"] = token
        }
        return headers
    }

    deinit {
        #if DEBUG
        print("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
