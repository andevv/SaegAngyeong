//
//  SceneDelegate.swift
//  SaegAngyeong
//
//  Created by andev on 12/10/25.
//

import UIKit
import iamport_ios
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var authCoordinator: AuthCoordinator?
    private var appDependency: AppDependency?
    private var fcmTokenObserver: NSObjectProtocol?
    private var chatRoomObserver: NSObjectProtocol?
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
        #if DEBUG
        print("[Deinit][SceneDelegate] \(type(of: self))")
        #endif
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
            self?.authCoordinator?.routeToChatRoom(roomID: roomID)
        }
    }

    private func routeToChatRoom(from userInfo: [AnyHashable: Any]) {
        let roomID = userInfo["room_id"] as? String ?? userInfo["roomId"] as? String
        guard let roomID, roomID.isEmpty == false else { return }
        authCoordinator?.routeToChatRoom(roomID: roomID)
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
