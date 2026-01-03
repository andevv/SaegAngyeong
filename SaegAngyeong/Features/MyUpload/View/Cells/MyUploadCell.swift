//
//  MyUploadCell.swift
//  SaegAngyeong
//
//  Created by andev on 1/3/26.
//

import UIKit
import SnapKit

final class MyUploadCell: UITableViewCell {
    static let reuseID = "MyUploadCell"

    private let cardView = UIView()
    private let thumbImageView = UIImageView()
    private let titleLabel = UILabel()
    private let creatorLabel = UILabel()
    private let likeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .blackTurquoise
        cardView.layer.cornerRadius = 16

        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 12
        thumbImageView.backgroundColor = .gray15

        titleLabel.font = .pretendard(.bold, size: 14)
        titleLabel.textColor = .gray30

        creatorLabel.font = .pretendard(.medium, size: 11)
        creatorLabel.textColor = .gray75

        likeLabel.font = .pretendard(.medium, size: 12)
        likeLabel.textColor = .brightTurquoise

        contentView.addSubview(cardView)
        cardView.addSubview(thumbImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(creatorLabel)
        cardView.addSubview(likeLabel)

        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        thumbImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(64)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(thumbImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(12)
        }

        creatorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
        }

        likeLabel.snp.makeConstraints { make in
            make.top.equalTo(creatorLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
    }

    func configure(with item: MyUploadItemViewData) {
        titleLabel.text = item.title
        creatorLabel.text = item.creator
        likeLabel.text = "♡ \(item.likeCountText)"
        KingfisherHelper.setImage(thumbImageView, url: item.thumbnailURL, headers: item.headers, logLabel: "myupload-thumb")
    }
}
