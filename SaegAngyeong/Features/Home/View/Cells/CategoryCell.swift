//
//  CategoryCell.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import UIKit
import SnapKit
import Kingfisher

final class CategoryCell: UICollectionViewCell {
    static let reuseID = "CategoryCell"

    private let iconView = UIImageView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .pretendard(.medium, size: 10)
        label.textColor = .gray60
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .gray75.withAlphaComponent(0.2)
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        iconView.tintColor = .gray60
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        iconView.contentMode = .scaleAspectFit

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: CategoryViewData) {
        iconView.image = UIImage(named: data.iconName)
        titleLabel.text = data.title
    }
}
