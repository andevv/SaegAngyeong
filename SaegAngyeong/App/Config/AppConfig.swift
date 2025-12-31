//
//  AppConfig.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import Foundation

enum AppConfig {

    // Private
    private static func value<T>(for key: String) -> T {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? T else {
            fatalError("\(key) not found in Info.plist")
        }
        return value
    }

    private static func optionalValue<T>(for key: String) -> T? {
        Bundle.main.object(forInfoDictionaryKey: key) as? T
    }

    // Public
    static let apiKey: String = value(for: "API_KEY")
    static let baseURL: String = value(for: "BASE_URL")
    static let iamportUserCode: String? = optionalValue(for: "IAMPORT_USER_CODE")
    static let iamportPG: String? = optionalValue(for: "IAMPORT_PG")
}
