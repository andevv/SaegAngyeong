//
//  AppLogger.swift
//  SaegAngyeong
//
//  Created by andev on 1/18/26.
//

import Foundation

enum AppLogger {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        let timestamp = formatter.string(from: Date())
        print("[\(timestamp)] \(message())")
        #endif
    }
}
