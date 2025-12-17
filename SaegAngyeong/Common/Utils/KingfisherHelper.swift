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
        placeholder: UIImage? = nil
    ) {
        guard let url else {
            imageView.image = placeholder
            return
        }
        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [.requestModifier(modifier(headers: headers))]
        )
    }
}
