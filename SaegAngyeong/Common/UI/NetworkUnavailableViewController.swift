//
//  NetworkUnavailableViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/18/26.
//

import UIKit
import SnapKit

final class NetworkUnavailableViewController: UIViewController {
    var onRetry: (() -> Void)?

    private let iconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "wifi.exclamationmark"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .gray45
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "네트워크 연결 오류"
        label.textColor = .gray30
        label.font = .mulgyeol(.bold, size: 20)
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "네트워크 상태가 원활하지 않습니다.\n연결을 확인한 뒤 다시 시도해주세요."
        label.textColor = .gray60
        label.font = .pretendard(.regular, size: 13)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("재시도", for: .normal)
        button.setTitleColor(.gray15, for: .normal)
        button.titleLabel?.font = .pretendard(.bold, size: 14)
        button.backgroundColor = .brightTurquoise
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureUI()
        configureLayout()
    }

    private func configureUI() {
        view.addSubview(iconView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(retryButton)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }

    private func configureLayout() {
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.height.equalTo(48)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        retryButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
