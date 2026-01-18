//
//  SceneDelegate.swift
//  SaegAngyeong
//
//  Created by andev on 12/10/25.
//

import UIKit
import iamport_ios
import Combine
import Network

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var authCoordinator: AuthCoordinator?
    private var appDependency: AppDependency?
    private var networkMonitor: NetworkStatusMonitor?
    private weak var networkAlert: UIAlertController?
    private var fcmTokenObserver: NSObjectProtocol?
    private var chatRoomObserver: NSObjectProtocol?
    private var lastChatRoute: (roomID: String, date: Date)?
    private var cancellables = Set<AnyCancellable>()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let dependency = AppDependency.make()
        let coordinator = AuthCoordinator(window: window, dependency: dependency)
        coordinator.start()
        
        self.authCoordinator = coordinator
        self.appDependency = dependency
        self.window = window
        startNetworkMonitor()
        registerFCMTokenObserver()
        registerChatRoomObserver()

        if let response = connectionOptions.notificationResponse {
            routeToChatRoom(from: response.notification.request.content.userInfo)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            Iamport.shared.receivedURL(url)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    deinit {
        if let observer = fcmTokenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = chatRoomObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        networkMonitor?.stop()
        #if DEBUG
        print("[Deinit][SceneDelegate] \(type(of: self))")
        #endif
    }

    private func startNetworkMonitor() {
        let monitor = NetworkStatusMonitor()
        monitor.onStatusChange = { [weak self] status in
            self?.handleNetworkStatusChange(status)
        }
        monitor.start()
        networkMonitor = monitor
    }

    private func handleNetworkStatusChange(_ status: Network.NWPath.Status) {
        switch status {
        case .unsatisfied:
            presentNetworkAlertIfNeeded()
        case .satisfied:
            dismissNetworkAlertIfNeeded()
        case .requiresConnection:
            presentNetworkAlertIfNeeded()
        @unknown default:
            break
        }
    }

    private func presentNetworkAlertIfNeeded() {
        guard networkAlert?.presentingViewController == nil else { return }
        guard let root = window?.rootViewController else { return }
        guard let top = topViewController(from: root) else { return }
        if top is UIAlertController { return }

        let alert = UIAlertController(
            title: "네트워크",
            message: "네트워크 상태가 원활하지 않습니다.",
            preferredStyle: .alert
        )
        let retryAction = UIAlertAction(title: "재시도", style: .default) { [weak self] _ in
            guard let self else { return }
            guard self.networkMonitor?.currentStatus == .satisfied else { return }
            self.dismissNetworkAlertIfNeeded()
            NotificationCenter.default.post(name: .networkRetryRequested, object: nil)
        }
        alert.addAction(retryAction)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        networkAlert = alert
        top.present(alert, animated: true)
    }

    private func dismissNetworkAlertIfNeeded() {
        guard let alert = networkAlert, alert.presentingViewController != nil else { return }
        alert.dismiss(animated: true)
        networkAlert = nil
    }

    private func topViewController(from root: UIViewController) -> UIViewController? {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }

    private func registerFCMTokenObserver() {
        guard fcmTokenObserver == nil else { return }
        fcmTokenObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("FCMToken"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let token = notification.userInfo?["token"] as? String,
                  token.isEmpty == false else { return }
            self?.appDependency?.tokenStore.deviceToken = token
            #if DEBUG
            print("[FCM] Stored device token: \(token)")
            #endif
            self?.updateDeviceTokenIfNeeded(token)
        }
    }

    private func registerChatRoomObserver() {
        guard chatRoomObserver == nil else { return }
        chatRoomObserver = NotificationCenter.default.addObserver(
            forName: .chatRoomRequested,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let roomID = notification.userInfo?["roomID"] as? String else { return }
            self?.routeToChatRoom(roomID: roomID)
        }
    }

    private func routeToChatRoom(from userInfo: [AnyHashable: Any]) {
        let roomID = userInfo["room_id"] as? String ?? userInfo["roomId"] as? String
        guard let roomID, roomID.isEmpty == false else { return }
        routeToChatRoom(roomID: roomID)
    }

    private func routeToChatRoom(roomID: String) {
        guard shouldHandleChatRoute(roomID: roomID) else { return }
        authCoordinator?.routeToChatRoom(roomID: roomID)
    }

    private func shouldHandleChatRoute(roomID: String) -> Bool {
        let now = Date()
        if let last = lastChatRoute,
           last.roomID == roomID,
           now.timeIntervalSince(last.date) < 1.0 {
            return false
        }
        lastChatRoute = (roomID, now)
        return true
    }

    private func updateDeviceTokenIfNeeded(_ token: String) {
        guard let appDependency else { return }
        guard let accessToken = appDependency.tokenStore.accessToken,
              accessToken.isEmpty == false else {
            return
        }
        appDependency.authRepository.updateDeviceToken(token)
            .sink { completion in
                #if DEBUG
                if case let .failure(error) = completion {
                    print("[FCM] Failed to update device token: \(error)")
                }
                #endif
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
