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
    private let playbackService: StreamingPlaybackService
    private var cancellables = Set<AnyCancellable>()

    init(
        navigationController: BaseNavigationController,
        videoRepository: VideoRepository,
        accessTokenProvider: @escaping () -> String?,
        sesacKey: String,
        playbackService: StreamingPlaybackService
    ) {
        self.navigationController = navigationController
        self.videoRepository = videoRepository
        self.accessTokenProvider = accessTokenProvider
        self.sesacKey = sesacKey
        self.playbackService = playbackService
    }

    func start() {
        let viewModel = StreamingListViewModel(
            videoRepository: videoRepository,
            accessTokenProvider: accessTokenProvider,
            sesacKey: sesacKey
        )
        let viewController = StreamingListViewController(viewModel: viewModel)
        viewController.onVideoSelected = { [weak self] videoID, title, viewCountText, likeCountText in
            self?.startStreaming(
                videoID: videoID,
                title: title,
                viewCountText: viewCountText,
                likeCountText: likeCountText
            )
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    func startStreaming(videoID: String, title: String, viewCountText: String, likeCountText: String) {
        hideMiniPlayer()
        let viewModel = StreamingViewModel(videoID: videoID, videoRepository: videoRepository)
        let viewController = StreamingViewController(
            viewModel: viewModel,
            videoID: videoID,
            playbackService: playbackService,
            viewCountText: viewCountText,
            likeCountText: likeCountText
        )
        playbackService.currentTitle = title
        playbackService.currentViewCountText = viewCountText
        playbackService.currentLikeCountText = likeCountText
        viewController.onCloseRequested = { [weak self] in
            self?.hideMiniPlayer()
            self?.navigationController.dismiss(animated: true)
        }
        viewController.onMiniPlayerRequested = { [weak self] in
            self?.showMiniPlayer()
            self?.navigationController.dismiss(animated: true)
        }
        viewController.modalPresentationStyle = .overFullScreen
        navigationController.present(viewController, animated: true)
    }

    private func showMiniPlayer() {
        (navigationController.tabBarController as? MainTabBarController)?.showMiniPlayer()
    }

    private func hideMiniPlayer() {
        (navigationController.tabBarController as? MainTabBarController)?.hideMiniPlayer()
    }

    deinit {
        #if DEBUG
        print("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
