//
//  FilterCompareView.swift
//  SaegAngyeong
//
//  Created by andev on 12/24/25.
//

import UIKit
import SnapKit
import Kingfisher

final class FilterCompareView: UIView {
    private let originalImageView = UIImageView()
    private let filteredImageView = UIImageView()
    private let maskLayer = CALayer()

    private var currentProgress: CGFloat = 0.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .blackTurquoise

        originalImageView.contentMode = .scaleAspectFill
        originalImageView.clipsToBounds = true
        addSubview(originalImageView)

        filteredImageView.contentMode = .scaleAspectFill
        filteredImageView.clipsToBounds = true
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.actions = [
            "bounds": NSNull(),
            "position": NSNull(),
            "frame": NSNull()
        ]
        filteredImageView.layer.mask = maskLayer
        addSubview(filteredImageView)

        originalImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        filteredImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImages(original: URL?, filtered: URL?, headers: [String: String]) {
        KingfisherHelper.setImage(originalImageView, url: original, headers: headers, logLabel: "detail-original")
        KingfisherHelper.setImage(filteredImageView, url: filtered, headers: headers, logLabel: "detail-filtered")
    }

    func setProgress(_ progress: CGFloat) {
        currentProgress = min(max(progress, 0.0), 1.0)
        updateMaskFrame()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMaskFrame()
    }

    private func updateMaskFrame() {
        let width = bounds.width * currentProgress
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
        CATransaction.commit()
    }
}
