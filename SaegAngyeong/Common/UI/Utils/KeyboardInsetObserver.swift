//
//  KeyboardInsetObserver.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import UIKit

final class KeyboardInsetObserver {
    private weak var scrollView: UIScrollView?
    private weak var containerView: UIView?
    private var observers: [NSObjectProtocol] = []

    init(scrollView: UIScrollView, containerView: UIView) {
        self.scrollView = scrollView
        self.containerView = containerView
    }

    func start() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        let willShow = center.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: true)
        }
        let willHide = center.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: false)
        }
        observers = [willShow, willHide]
    }

    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    private func handleKeyboard(notification: Notification, isShowing: Bool) {
        guard let info = notification.userInfo,
              let frameValue = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
              let scrollView,
              let containerView else {
            return
        }
        let keyboardFrame = frameValue.cgRectValue
        let keyboardHeight = isShowing ? keyboardFrame.height - containerView.safeAreaInsets.bottom : 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            scrollView.contentInset.bottom = keyboardHeight + 12
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight + 12
        }
    }
}
