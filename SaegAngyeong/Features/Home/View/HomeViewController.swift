//
//  HomeViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/15/25.
//

import UIKit
import SnapKit
import Combine
import Kingfisher

final class HomeViewController: BaseViewController<HomeViewModel> {

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let overlayGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.clear.cgColor
        ]
        layer.locations = [0.0, 0.7]
        return layer
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.8)
        label.font = .pretendard(.medium, size: 13)
        label.text = "오늘의 필터 소개"
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .mulgyeol(.bold, size: 32)
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.9)
        label.font = .pretendard(.regular, size: 12)
        label.numberOfLines = 0
        return label
    }()

    private let useButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("사용해보기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 12)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        button.layer.borderWidth = 1
        return button
    }()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()

    override init(viewModel: HomeViewModel) {
        super.init(viewModel: viewModel)
        tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "Home_Empty"),
            selectedImage: UIImage(named: "Home_Fill")
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        viewDidLoadSubject.send(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        overlayGradient.frame = backgroundImageView.bounds
    }

    override func configureUI() {
        view.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(overlayGradient)
        [subtitleLabel, titleLabel, descriptionLabel, useButton].forEach { view.addSubview($0) }
    }

    override func configureLayout() {
        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(view.snp.width).multipliedBy(1.1)
        }

        useButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.trailing.equalToSuperview().inset(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(backgroundImageView.snp.bottom).inset(80)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalTo(titleLabel.snp.top).offset(-12)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
        }
    }

    override func bindViewModel() {
        let input = HomeViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.highlight
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewData in
                self?.titleLabel.text = viewData.title
                self?.descriptionLabel.text = viewData.description
                self?.subtitleLabel.text = "오늘의 필터 소개"
                self?.loadImage(from: viewData.imageURL, headers: viewData.headers)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func loadImage(from url: URL?, headers: [String: String]) {
        guard let url else { return }
        let modifier = AnyModifier { request in
            var r = request
            headers.forEach { key, value in
                r.setValue(value, forHTTPHeaderField: key)
            }
            return r
        }
        backgroundImageView.kf.setImage(with: url, options: [.requestModifier(modifier)]) { result in
            if case let .failure(error) = result {
                print("[Home] image load failed:", error)
            }
        }
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
