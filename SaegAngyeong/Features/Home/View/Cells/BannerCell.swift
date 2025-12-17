//
//  BannerCell.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import UIKit
import SnapKit
import Kingfisher

final class BannerCell: UICollectionViewCell {
    static let reuseID = "BannerCell"

    private let containerView = UIView()
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 25
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.contentMode = .scaleAspectFill
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: BannerViewData) {
        let modifier = AnyModifier { request in
            var r = request
            data.headers.forEach { key, value in r.setValue(value, forHTTPHeaderField: key) }
            return r
        }
        if let url = data.imageURL {
            imageView.kf.setImage(with: url, options: [.requestModifier(modifier)])
        } else {
            imageView.image = nil
            contentView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        }
    }
}
