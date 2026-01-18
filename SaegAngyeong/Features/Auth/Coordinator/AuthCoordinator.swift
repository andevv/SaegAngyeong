//
//  AuthCoordinator.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit
import Combine

final class AuthCoordinator {

    // MARK: - Properties
    private let dependency: AppDependency
    let navigationController: BaseNavigationController
    private var window: UIWindow?
    private var cancellables = Set<AnyCancellable>()
    private weak var mainTabBarController: MainTabBarController?

    init(window: UIWindow?, dependency: AppDependency) {
        self.window = window
        self.dependency = dependency
        self.navigationController = BaseNavigationController()
        bindTokenInvalidation()
    }

    func start() {
        guard hasAccessToken else {
            showLogin(animated: false)
            return
        }
        showHome(animated: false)
    }

    // MARK: - Private

    private var hasAccessToken: Bool {
        guard let token = dependency.tokenStore.accessToken else { return false }
        return !token.isEmpty
    }

    private func showLogin(animated: Bool) {
        let viewModel = LoginViewModel(
            authRepository: dependency.authRepository,
            deviceTokenProvider: { self.dependency.tokenStore.deviceToken }
        )
        let loginVC = LoginViewController(viewModel: viewModel)
        loginVC.onLoginSuccess = { [weak self] session in
            self?.dependency.tokenStore.accessToken = session.tokens.accessToken
            self?.dependency.tokenStore.refreshToken = session.tokens.refreshToken
            self?.sendDeviceTokenIfNeeded()
            self?.showHome(animated: true)
        }
        loginVC.onJoinRequested = { [weak self] in
            self?.showJoin()
        }
        navigationController.setViewControllers([loginVC], animated: animated)
        setRootViewController(navigationController, animated: animated)
    }

    private func showJoin() {
        let viewModel = JoinViewModel(
            authRepository: dependency.authRepository,
            deviceTokenProvider: { self.dependency.tokenStore.deviceToken }
        )
        let joinVC = JoinViewController(viewModel: viewModel)
        joinVC.onJoinSuccess = { [weak self] session in
            self?.dependency.tokenStore.accessToken = session.tokens.accessToken
            self?.dependency.tokenStore.refreshToken = session.tokens.refreshToken
            self?.sendDeviceTokenIfNeeded()
            self?.showHome(animated: true)
        }
        navigationController.pushViewController(joinVC, animated: true)
    }

    private func showHome(animated: Bool) {
        let tabBar = MainTabBarController(dependency: dependency)
        mainTabBarController = tabBar
        setRootViewController(tabBar, animated: animated)
    }

    func routeToChatRoom(roomID: String) {
        guard hasAccessToken else {
            showLogin(animated: false)
            return
        }
        if let tabBar = window?.rootViewController as? MainTabBarController {
            mainTabBarController = tabBar
        } else if mainTabBarController == nil {
            showHome(animated: false)
        }
        DispatchQueue.main.async { [weak self] in
            self?.mainTabBarController?.routeToChatRoom(roomID: roomID)
        }
    }

    private func bindTokenInvalidation() {
        NotificationCenter.default.publisher(for: .tokenInvalidated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dependency.tokenStore.clear()
                self?.showLogin(animated: true)
            }
            .store(in: &cancellables)
    }

    private func sendDeviceTokenIfNeeded() {
        guard let token = dependency.tokenStore.deviceToken, token.isEmpty == false else { return }
        dependency.authRepository.updateDeviceToken(token)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    private func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        guard let window else { return }
        if animated {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = viewController
            }, completion: nil)
        } else {
            window.rootViewController = viewController
        }
        window.makeKeyAndVisible()
    }

    deinit {
        #if DEBUG
        AppLogger.debug("[Deinit][Coordinator] \(type(of: self))")
        #endif
    }
}
