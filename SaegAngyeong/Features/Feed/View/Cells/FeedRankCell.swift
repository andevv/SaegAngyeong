//
//  FeedRankCell.swift
//  SaegAngyeong
//
//  Created by andev on 12/22/25.
//

import UIKit
import SnapKit

final class FeedRankCell: UICollectionViewCell {
    static let reuseID = "FeedRankCell"

    private let containerView = UIView()
    private let imageContainerView = UIView()
    private let imageView = UIImageView()
    private let creatorLabel = UILabel()
    private let titleLabel = UILabel()
    private let categoryLabel = UILabel()
    private let rankBadgeView = UIView()
    private let rankLabel = UILabel()
    private let shadowView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        shadowView.backgroundColor = .clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.35
        shadowView.layer.shadowRadius = 16
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        contentView.addSubview(shadowView)

        containerView.backgroundColor = .blackTurquoise
        containerView.clipsToBounds = true
        shadowView.addSubview(containerView)

        imageContainerView.backgroundColor = .clear
        imageContainerView.layer.borderWidth = 0
        imageContainerView.clipsToBounds = true
        containerView.addSubview(imageContainerView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageContainerView.addSubview(imageView)

        creatorLabel.font = .pretendard(.medium, size: 12)
        creatorLabel.textColor = .gray75
        creatorLabel.textAlignment = .center
        containerView.addSubview(creatorLabel)

        titleLabel.font = .mulgyeol(.bold, size: 24)
        titleLabel.textColor = .gray30
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        categoryLabel.font = .pretendard(.medium, size: 12)
        categoryLabel.textColor = .gray75
        categoryLabel.textAlignment = .center
        containerView.addSubview(categoryLabel)

        rankBadgeView.backgroundColor = UIColor.blackTurquoise
        rankBadgeView.layer.borderWidth = 1
        rankBadgeView.layer.borderColor = UIColor.deepTurquoise.cgColor
        contentView.addSubview(rankBadgeView)

        rankLabel.font = .mulgyeol(.bold, size: 32)
        rankLabel.textColor = .brightTurquoise
        rankLabel.textAlignment = .center
        rankBadgeView.addSubview(rankLabel)

        shadowView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(44)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(28)
        }

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(230)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        creatorLabel.snp.makeConstraints { make in
            make.top.equalTo(imageContainerView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(creatorLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(24)
        }

        rankBadgeView.snp.makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.centerY.equalTo(containerView.snp.bottom)
            make.width.height.equalTo(44)
        }

        rankLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        setNeedsLayout()
        layoutIfNeeded()
        updateCorners()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorners()
    }

    func configure(with data: FeedRankViewData) {
        creatorLabel.text = data.creatorNick.uppercased()
        titleLabel.text = data.title
        categoryLabel.text = "#\(data.category)"
        rankLabel.text = "\(data.rank)"

        if let url = data.imageURL {
            KingfisherHelper.setImage(imageView, url: url, headers: data.headers, logLabel: "feed-rank")
        } else {
            imageView.image = UIImage(named: "Filter_Empty")
        }
    }

    private func updateCorners() {
        imageContainerView.layer.cornerRadius = imageContainerView.bounds.width / 2
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        rankBadgeView.layer.cornerRadius = rankBadgeView.bounds.width / 2
        let capsuleRadius = min(containerView.bounds.width, containerView.bounds.height) / 2
        containerView.layer.cornerRadius = capsuleRadius
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: capsuleRadius).cgPath
    }
}
