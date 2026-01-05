//
//  MyChattingListCell.swift
//  SaegAngyeong
//
//  Created by andev on 1/5/26.
//

import UIKit
import SnapKit
import Kingfisher

final class MyChattingListCell: UITableViewCell {
    static let reuseID = "MyChattingListCell"

    private let cardView = UIView()
    private let profileImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let messageLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .blackTurquoise
        cardView.layer.cornerRadius = 16

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 18
        profileImageView.backgroundColor = .gray15

        titleLabel.font = .pretendard(.bold, size: 14)
        titleLabel.textColor = .gray30

        subtitleLabel.font = .pretendard(.medium, size: 11)
        subtitleLabel.textColor = .gray75

        messageLabel.font = .pretendard(.regular, size: 12)
        messageLabel.textColor = .gray60
        messageLabel.numberOfLines = 2

        dateLabel.font = .pretendard(.regular, size: 11)
        dateLabel.textColor = .gray60

        contentView.addSubview(cardView)
        cardView.addSubview(profileImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(messageLabel)
        cardView.addSubview(dateLabel)

        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(56)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(profileImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(dateLabel.snp.leading).offset(-8)
        }

        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(12)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(12)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
    }

    func configure(with item: MyChattingListItemViewData) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        messageLabel.text = item.lastMessage
        dateLabel.text = item.updatedAtText
        if let url = item.profileImageURL {
            KingfisherHelper.setImage(
                profileImageView,
                url: url,
                headers: item.headers,
                placeholder: UIImage(named: "Profile_Empty"),
                logLabel: "chat-profile"
            )
        } else {
            profileImageView.image = UIImage(named: "Profile_Empty")
        }
    }
}
