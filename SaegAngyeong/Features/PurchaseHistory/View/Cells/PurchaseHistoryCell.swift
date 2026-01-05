//
//  PurchaseHistoryCell.swift
//  SaegAngyeong
//
//  Created by andev on 1/5/26.
//

import UIKit
import SnapKit
import Kingfisher

final class PurchaseHistoryCell: UITableViewCell {
    static let reuseID = "PurchaseHistoryCell"

    private let cardView = UIView()
    private let thumbImageView = UIImageView()
    private let titleLabel = UILabel()
    private let creatorLabel = UILabel()
    private let priceLabel = UILabel()
    private let dateLabel = UILabel()

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

        priceLabel.font = .pretendard(.bold, size: 12)
        priceLabel.textColor = .brightTurquoise

        dateLabel.font = .pretendard(.regular, size: 11)
        dateLabel.textColor = .gray60

        contentView.addSubview(cardView)
        cardView.addSubview(thumbImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(creatorLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(dateLabel)

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

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(creatorLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }

        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(priceLabel)
            make.trailing.equalToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
    }

    func configure(with item: PurchaseHistoryItemViewData) {
        titleLabel.text = item.title
        creatorLabel.text = item.creator
        priceLabel.text = item.priceText
        dateLabel.text = item.paidAtText
        if let url = item.thumbnailURL {
            KingfisherHelper.setImage(thumbImageView, url: url, headers: [:], logLabel: "purchase-thumb")
        } else {
            thumbImageView.image = UIImage(named: "Home_Empty")
        }
    }
}
