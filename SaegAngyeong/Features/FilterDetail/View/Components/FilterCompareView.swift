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
    private let filteredMaskView = UIView()
    private var filteredWidthConstraint: Constraint?

    private var currentProgress: CGFloat = 0.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = .blackTurquoise

        originalImageView.contentMode = .scaleAspectFill
        originalImageView.clipsToBounds = true
        addSubview(originalImageView)

        filteredMaskView.clipsToBounds = true
        addSubview(filteredMaskView)

        filteredImageView.contentMode = .scaleAspectFill
        filteredImageView.clipsToBounds = true
        filteredMaskView.addSubview(filteredImageView)

        originalImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        filteredMaskView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            filteredWidthConstraint = make.width.equalTo(0).constraint
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
        if let superview = filteredMaskView.superview {
            let newWidth = superview.bounds.width * currentProgress
            filteredWidthConstraint?.update(offset: newWidth)
            layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setProgress(currentProgress)
    }
}
