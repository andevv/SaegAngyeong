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
    let navigationController: UINavigationController
    private var window: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow?, dependency: AppDependency) {
        self.window = window
        self.dependency = dependency
        self.navigationController = UINavigationController()
        bindTokenInvalidation()
    }

    func start() {
        guard hasAccessToken else {
            showLogin(animated: false)
            return
        }
        attemptRefreshOrLogin()
    }

    // MARK: - Private

    private var hasAccessToken: Bool {
        guard let token = dependency.tokenStore.accessToken else { return false }
        return !token.isEmpty
    }

    private func attemptRefreshOrLogin() {
        guard let refreshToken = dependency.tokenStore.refreshToken else {
            showHome(animated: false)
            return
        }

        dependency.authRepository.refresh(refreshToken: refreshToken)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.showLogin(animated: false)
                }
            } receiveValue: { [weak self] tokens in
                self?.dependency.tokenStore.accessToken = tokens.accessToken
                self?.dependency.tokenStore.refreshToken = tokens.refreshToken
                self?.showHome(animated: false)
            }
            .store(in: &cancellables)
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
            self?.showHome(animated: true)
        }
        navigationController.setViewControllers([loginVC], animated: animated)
        setRootViewController(navigationController, animated: animated)
    }

    private func showHome(animated: Bool) {
        let tabBar = MainTabBarController(dependency: dependency)
        setRootViewController(tabBar, animated: animated)
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
}
