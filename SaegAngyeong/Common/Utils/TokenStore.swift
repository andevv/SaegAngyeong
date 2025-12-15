//
//  TokenStore.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import Foundation
import Security

/// 키체인 기반 토큰 저장소
final class TokenStore {
    private enum Key: String {
        case accessToken = "com.saegangyeong.token.access"
        case refreshToken = "com.saegangyeong.token.refresh"
        case deviceToken = "com.saegangyeong.token.device"
    }

    var accessToken: String? {
        get { read(.accessToken) }
        set { write(newValue, for: .accessToken) }
    }

    var refreshToken: String? {
        get { read(.refreshToken) }
        set { write(newValue, for: .refreshToken) }
    }

    var deviceToken: String? {
        get { read(.deviceToken) }
        set { write(newValue, for: .deviceToken) }
    }

    func clear() {
        delete(.accessToken)
        delete(.refreshToken)
    }

    // MARK: - Keychain Helpers

    private func write(_ value: String?, for key: Key) {
        guard let value else {
            delete(key)
            return
        }

        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.rawValue
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func read(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        return value
    }

    private func delete(_ key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
