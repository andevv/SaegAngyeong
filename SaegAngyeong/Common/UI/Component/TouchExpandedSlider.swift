//
//  TouchExpandedSlider.swift
//  SaegAngyeong
//
//  Created by andev on 1/15/26.
//

import UIKit

final class TouchExpandedSlider: UISlider {
    private let touchInsets: UIEdgeInsets

    init(touchInsets: UIEdgeInsets) {
        self.touchInsets = touchInsets
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.inset(by: UIEdgeInsets(
            top: -touchInsets.top,
            left: -touchInsets.left,
            bottom: -touchInsets.bottom,
            right: -touchInsets.right
        ))
        return expandedBounds.contains(point)
    }
}
