//
//  PaddingLabel.swift
//  SaegAngyeong
//
//  Created by andev on 12/16/25.
//

import UIKit

/// Insets를 적용할 수 있는 UILabel
final class PaddingLabel: UILabel {
    private let padding: UIEdgeInsets

    init(padding: UIEdgeInsets) {
        self.padding = padding
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right,
                      height: size.height + padding.top + padding.bottom)
    }
}
