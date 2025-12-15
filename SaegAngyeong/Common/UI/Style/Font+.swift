//
//  Font+.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit

// MARK: - Pretendard

enum PretendardWeight {
    case regular
    case medium
    case bold

    var fontName: String {
        switch self {
        case .regular: return "Pretendard-Regular"
        case .medium:  return "Pretendard-Medium"
        case .bold:    return "Pretendard-Bold"
        }
    }
}

// MARK: - Hakgyoansim Mulgyeol

enum MulgyeolWeight {
    case regular
    case bold

    var fontName: String {
        switch self {
        case .regular: return "OTHakgyoansimMulgyeolR"
        case .bold:    return "OTHakgyoansimMulgyeolB"
        }
    }
}

extension UIFont {

    // Pretendard
    static func pretendard(
        _ weight: PretendardWeight,
        size: CGFloat
    ) -> UIFont {
        UIFont(
            name: weight.fontName,
            size: size
        ) ?? .systemFont(ofSize: size)
    }

    // Hakgyoansim Mulgyeol
    static func mulgyeol(
        _ weight: MulgyeolWeight,
        size: CGFloat
    ) -> UIFont {
        UIFont(
            name: weight.fontName,
            size: size
        ) ?? .systemFont(ofSize: size)
    }
}
