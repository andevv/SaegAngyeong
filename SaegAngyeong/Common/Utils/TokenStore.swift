//
//  TokenStore.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation

/// 간단한 토큰 저장소 (UserDefaults 기반)
final class TokenStore {
    private let defaults = UserDefaults.standard
    private enum Key {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let deviceToken = "deviceToken"
    }

    var accessToken: String? {
        get { defaults.string(forKey: Key.accessToken) }
        set { defaults.setValue(newValue, forKey: Key.accessToken) }
    }

    var refreshToken: String? {
        get { defaults.string(forKey: Key.refreshToken) }
        set { defaults.setValue(newValue, forKey: Key.refreshToken) }
    }

    var deviceToken: String? {
        get { defaults.string(forKey: Key.deviceToken) }
        set { defaults.setValue(newValue, forKey: Key.deviceToken) }
    }

    func clear() {
        defaults.removeObject(forKey: Key.accessToken)
        defaults.removeObject(forKey: Key.refreshToken)
    }
}
