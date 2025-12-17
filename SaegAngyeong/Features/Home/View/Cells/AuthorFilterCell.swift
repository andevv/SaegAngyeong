//
//  AuthorFilterCell.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import UIKit
import SnapKit
import Kingfisher

final class AuthorFilterCell: UICollectionViewCell {
    static let reuseID = "AuthorFilterCell"

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: AuthorFilterViewData) {
        if let url = data.imageURL {
            KingfisherHelper.setImage(imageView, url: url, headers: data.headers)
        } else {
            imageView.image = nil
        }
    }
}
