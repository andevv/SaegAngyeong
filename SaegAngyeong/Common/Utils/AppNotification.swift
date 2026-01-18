//
//  AppNotification.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

extension Notification.Name {
    static let tokenInvalidated = Notification.Name("TokenInvalidatedNotification")
    static let chatRoomRequested = Notification.Name("ChatRoomRequestedNotification")
    static let networkRetryRequested = Notification.Name("NetworkRetryRequestedNotification")
}
