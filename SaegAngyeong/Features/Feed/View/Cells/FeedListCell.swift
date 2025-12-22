//
//  FeedListCell.swift
//  SaegAngyeong
//
//  Created by andev on 12/22/25.
//

import UIKit
import SnapKit

final class FeedListCell: UICollectionViewCell {
    static let reuseID = "FeedListCell"

    private let containerView = UIView()
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let categoryBadge = PaddingLabel(padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
    private let creatorLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    var onLikeTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        containerView.backgroundColor = .black
        contentView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
        containerView.addSubview(thumbnailImageView)

        titleLabel.font = .mulgyeol(.bold, size: 20)
        titleLabel.textColor = .gray30
        titleLabel.numberOfLines = 1
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        containerView.addSubview(titleLabel)

        categoryBadge.font = .pretendard(.medium, size: 11)
        categoryBadge.textColor = .gray60
        categoryBadge.backgroundColor = .blackTurquoise
        categoryBadge.layer.cornerRadius = 10
        categoryBadge.clipsToBounds = true
        categoryBadge.setContentHuggingPriority(.required, for: .horizontal)
        categoryBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        containerView.addSubview(categoryBadge)

        creatorLabel.font = .pretendard(.bold, size: 14)
        creatorLabel.textColor = .gray75
        containerView.addSubview(creatorLabel)

        descriptionLabel.font = .pretendard(.regular, size: 12)
        descriptionLabel.textColor = .gray60
        descriptionLabel.numberOfLines = 3
        containerView.addSubview(descriptionLabel)

        likeButton.tintColor = .gray30
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        containerView.addSubview(likeButton)

        thumbnailImageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(thumbnailImageView.snp.height).multipliedBy(0.75)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualTo(categoryBadge.snp.leading).offset(-8)
        }

        categoryBadge.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        creatorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(creatorLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(12)
        }

        likeButton.snp.makeConstraints { make in
            make.trailing.equalTo(thumbnailImageView.snp.trailing).inset(4)
            make.bottom.equalTo(thumbnailImageView.snp.bottom).inset(4)
            make.width.height.equalTo(28)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: FeedItemViewData) {
        titleLabel.text = data.title
        creatorLabel.text = data.creatorNick.uppercased()
        categoryBadge.text = "#\(data.category)"
        descriptionLabel.text = data.description
        let heartName = data.isLiked ? "Icon_Like_Fill" : "Icon_Like_Empty"
        likeButton.setImage(UIImage(named: heartName), for: .normal)

        KingfisherHelper.setImage(
            thumbnailImageView,
            url: data.imageURL,
            headers: data.headers,
            logLabel: "feed-list"
        )
    }

    @objc private func likeTapped() {
        onLikeTap?()
    }
}
