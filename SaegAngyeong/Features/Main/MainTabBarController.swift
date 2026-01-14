//
//  MainTabBarController.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit
import SnapKit

final class MainTabBarController: UITabBarController {

    private let dependency: AppDependency
    private let homeCoordinator: HomeCoordinator
    private let feedCoordinator: FeedCoordinator
    private let filterMakeCoordinator: FilterMakeCoordinator
    private let myPageCoordinator: MyPageCoordinator
    private let miniPlayerView = MiniPlayerView()
    private var streamingCoordinator: StreamingCoordinator?

    init(dependency: AppDependency) {
        self.dependency = dependency
        self.homeCoordinator = HomeCoordinator(dependency: dependency)
        self.feedCoordinator = FeedCoordinator(dependency: dependency)
        self.filterMakeCoordinator = FilterMakeCoordinator(dependency: dependency)
        self.myPageCoordinator = MyPageCoordinator(dependency: dependency)
        super.init(nibName: nil, bundle: nil)
        configureAppearance()
        setupTabs(dependency: dependency)
        setupMiniPlayer()
        delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        #if DEBUG
        print("[Deinit][VC] \(type(of: self))")
        #endif
    }

    private func configureAppearance() {
        tabBar.tintColor = .gray15
        tabBar.unselectedItemTintColor = .gray45
    }

    override var childForStatusBarStyle: UIViewController? {
        selectedViewController
    }

    func routeToChatRoom(roomID: String) {
        selectedIndex = 4
        myPageCoordinator.routeToChatRoom(roomID: roomID)
    }

    private func setupTabs(dependency: AppDependency) {
        let homeVC = homeCoordinator.start()
        let feedVC = feedCoordinator.start()
        let filterMakeVC = filterMakeCoordinator.start()

        let myPageVC = myPageCoordinator.start()

        let dummy3 = DummyViewController(titleText: "", named: "Search_Empty", tag: 3, color: .systemGray4)

        viewControllers = [
            homeVC,
            feedVC,
            filterMakeVC,
            dummy3,
            myPageVC
        ]
        selectedIndex = 0
    }

    private func setupMiniPlayer() {
        miniPlayerView.isHidden = true
        miniPlayerView.bind(service: dependency.streamingPlaybackService)
        miniPlayerView.onExpand = { [weak self] in
            self?.presentStreamingFromMini()
        }
        miniPlayerView.onClose = { [weak self] in
            self?.dependency.streamingPlaybackService.stop()
            self?.hideMiniPlayer()
        }
        view.addSubview(miniPlayerView)
        miniPlayerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(tabBar.snp.top).offset(-8)
            make.height.equalTo(60)
        }
    }

    func showMiniPlayer() {
        miniPlayerView.isHidden = false
        view.bringSubviewToFront(miniPlayerView)
    }

    func hideMiniPlayer() {
        miniPlayerView.isHidden = true
    }

    private func presentStreamingFromMini() {
        guard let videoID = dependency.streamingPlaybackService.currentVideoID else { return }
        guard let presenter = selectedViewController as? BaseNavigationController else { return }
        let coordinator = StreamingCoordinator(
            navigationController: presenter,
            videoRepository: dependency.videoRepository,
            accessTokenProvider: { [weak self] in self?.dependency.tokenStore.accessToken },
            sesacKey: AppConfig.apiKey,
            playbackService: dependency.streamingPlaybackService
        )
        streamingCoordinator = coordinator
        coordinator.startStreaming(videoID: videoID)
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

    deinit {
        #if DEBUG
        print("[Deinit][VC] \(type(of: self))")
        #endif
    }
}
