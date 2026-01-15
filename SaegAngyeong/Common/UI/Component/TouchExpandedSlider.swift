//
//  TouchExpandedSlider.swift
//  SaegAngyeong
//
//  Created by andev on 1/15/26.
//

import UIKit

final class TouchExpandedSlider: UISlider {
    private let touchInsets: UIEdgeInsets
    private let trackHeight: CGFloat

    init(touchInsets: UIEdgeInsets, trackHeight: CGFloat) {
        self.touchInsets = touchInsets
        self.trackHeight = trackHeight
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

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.trackRect(forBounds: bounds)
        let y = rect.midY - trackHeight / 2
        return CGRect(x: rect.origin.x, y: y, width: rect.width, height: trackHeight)
    }
}
