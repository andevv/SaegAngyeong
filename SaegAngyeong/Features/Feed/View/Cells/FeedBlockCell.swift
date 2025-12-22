//
//  FeedBlockCell.swift
//  SaegAngyeong
//
//  Created by andev on 12/22/25.
//

import UIKit
import SnapKit

final class FeedBlockCell: UICollectionViewCell {
    static let reuseID = "FeedBlockCell"

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let creatorLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    private let likeLabel = UILabel()
    private var imageHeightConstraint: Constraint?
    var onLikeTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        contentView.addSubview(imageView)

        titleLabel.font = .mulgyeol(.bold, size: 14)
        titleLabel.textColor = .gray30
        contentView.addSubview(titleLabel)

        creatorLabel.font = .pretendard(.bold, size: 12)
        creatorLabel.textColor = .gray75
        contentView.addSubview(creatorLabel)

        likeButton.tintColor = .gray30
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        contentView.addSubview(likeButton)

        likeLabel.font = .pretendard(.medium, size: 12)
        likeLabel.textColor = .gray30
        contentView.addSubview(likeLabel)

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            imageHeightConstraint = make.height.equalTo(200).constraint
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.top).offset(12)
            make.leading.equalTo(imageView.snp.leading).offset(12)
            make.trailing.lessThanOrEqualTo(imageView.snp.trailing).inset(12)
        }

        likeButton.snp.makeConstraints { make in
            make.bottom.equalTo(imageView.snp.bottom).inset(10)
            make.trailing.equalTo(imageView.snp.trailing).inset(12)
            make.width.height.equalTo(22)
        }

        likeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(likeButton)
            make.trailing.equalTo(likeButton.snp.leading).offset(-6)
        }

        creatorLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(-4)
            make.leading.equalToSuperview().offset(4)
            make.trailing.lessThanOrEqualToSuperview().inset(4)
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: FeedItemViewData) {
        titleLabel.text = data.title
        creatorLabel.text = data.creatorNick.uppercased()
        likeLabel.text = "\(data.likeCount)"
        let heartName = data.isLiked ? "Icon_Like_Fill" : "Icon_Like_Empty"
        likeButton.setImage(UIImage(named: heartName), for: .normal)
        imageHeightConstraint?.update(offset: data.masonryHeight)

        KingfisherHelper.setImage(
            imageView,
            url: data.imageURL,
            headers: data.headers,
            logLabel: "feed-block"
        )
    }

    @objc private func likeTapped() {
        onLikeTap?()
    }
}
