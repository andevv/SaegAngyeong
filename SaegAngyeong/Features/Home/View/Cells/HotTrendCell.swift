//
//  HotTrendCell.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import UIKit
import SnapKit
import Kingfisher

final class HotTrendCell: UICollectionViewCell {
    static let reuseID = "HotTrendCell"

    private let containerView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let likeStack = UIStackView()
    private let likeIcon = UIImageView()
    private let likeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.font = .mulgyeol(.regular, size: 14)
        titleLabel.textColor = .gray30
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().inset(12)
        }

        likeIcon.image = UIImage(systemName: "heart.fill")
        likeIcon.tintColor = .gray30
        likeLabel.font = .pretendard(.medium, size: 12)
        likeLabel.textColor = .gray30
        likeStack.axis = .horizontal
        likeStack.spacing = 4
        likeStack.alignment = .center
        likeStack.addArrangedSubview(likeIcon)
        likeStack.addArrangedSubview(likeLabel)
        containerView.addSubview(likeStack)
        likeStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: HotTrendViewData) {
        titleLabel.text = data.title
        likeLabel.text = "\(data.likeCount)"

        let modifier = AnyModifier { request in
            var r = request
            data.headers.forEach { key, value in r.setValue(value, forHTTPHeaderField: key) }
            return r
        }
        if let url = data.imageURL {
            imageView.kf.setImage(with: url, options: [.requestModifier(modifier)])
        } else {
            imageView.image = nil
        }
    }
}
