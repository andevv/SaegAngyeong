//
//  StreamingCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import UIKit
import Combine

final class StreamingCoordinator {
    private let navigationController: BaseNavigationController
    private let videoRepository: VideoRepository
    private let accessTokenProvider: () -> String?
    private let sesacKey: String
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: BaseNavigationController,
        videoRepository: VideoRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String
    ) {
        self.navigationController = navigationController
        self.videoRepository = videoRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
    }

    func start() {
        let viewModel = StreamingListViewModel(
            videoRepository: videoRepository,
            accessTokenProvider: accessTokenProvider,
            sesacKey: sesacKey
        )
        let viewController = StreamingListViewController(viewModel: viewModel)
        viewController.onVideoSelected = { [weak self] videoID in
            self?.showStreaming(videoID: videoID)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showStreaming(videoID: String) {
        let viewModel = StreamingViewModel(videoID: videoID, videoRepository: videoRepository)
        let viewController = StreamingViewController(viewModel: viewModel)
        viewController.modalPresentationStyle = .fullScreen
        navigationController.present(viewController, animated: true)
    }

    deinit {
        #if DEBUG
        print("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
