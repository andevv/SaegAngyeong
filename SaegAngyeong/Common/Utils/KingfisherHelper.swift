//
//  KingfisherHelper.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import Foundation
import Kingfisher
import UIKit

enum KingfisherHelper {
    /// Build request modifier from headers
    static func modifier(headers: [String: String]) -> AnyModifier {
        AnyModifier { request in
            var r = request
            headers.forEach { key, value in r.setValue(value, forHTTPHeaderField: key) }
            return r
        }
    }

    /// Convenience to set image with headers
    static func setImage(
        _ imageView: UIImageView,
        url: URL?,
        headers: [String: String],
        placeholder: UIImage? = nil,
        logLabel: String? = nil
    ) {
        guard let url else {
            imageView.image = placeholder
            return
        }
        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [.requestModifier(modifier(headers: headers))]
        ) { result in
            #if DEBUG
            switch result {
            case .success(let value):
                let source: String
                switch value.cacheType {
                case .memory: source = "memory-cache"
                case .disk: source = "disk-cache"
                case .none: source = "network"
                @unknown default: source = "unknown"
                }
                AppLogger.debug("[KF] \(logLabel ?? "") \(url.absoluteString) -> \(source)")
            case .failure(let error):
                AppLogger.debug("[KF][Error] \(logLabel ?? "") \(url.absoluteString) -> \(error)")
            }
            #endif
        }
    }
}
