//
//  FilterDetailViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/24/25.
//

import UIKit
import SnapKit
import Combine
import MapKit

final class FilterDetailViewController: BaseViewController<FilterDetailViewModel> {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let compareContainerView = UIView()
    private let compareView = FilterCompareView()
    private let compareBar = UIView()
    private let afterLabel = UILabel()
    private let beforeLabel = UILabel()
    private let compareThumb = UIView()

    private let priceLabel = UILabel()
    private let coinLabel = UILabel()

    private let statsStack = UIStackView()
    private let downloadCard = StatCardView()
    private let likeCard = StatCardView()

    private let metadataCard = MetadataCardView()

    private let likeButton = UIButton(type: .system)

    private var compareProgress: CGFloat = 0.5

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let likeToggleSubject = PassthroughSubject<Void, Never>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        viewDidLoadSubject.send(())
    }

    override func configureUI() {
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        compareContainerView.backgroundColor = .blackTurquoise
        compareContainerView.layer.cornerRadius = 16
        compareContainerView.clipsToBounds = true

        afterLabel.text = "After"
        afterLabel.textColor = .gray60
        afterLabel.font = .pretendard(.medium, size: 12)

        beforeLabel.text = "Before"
        beforeLabel.textColor = .gray60
        beforeLabel.font = .pretendard(.medium, size: 12)

        compareBar.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        compareBar.layer.cornerRadius = 12

        compareThumb.backgroundColor = .gray90
        compareThumb.layer.cornerRadius = 16
        compareThumb.layer.borderWidth = 1
        compareThumb.layer.borderColor = UIColor.gray75.cgColor

        priceLabel.font = .mulgyeol(.bold, size: 28)
        priceLabel.textColor = .gray30

        coinLabel.font = .pretendard(.bold, size: 18)
        coinLabel.textColor = .gray60

        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        downloadCard.configure(title: "다운로드", value: "-")
        likeCard.configure(title: "찜하기", value: "-")

        likeButton.setImage(UIImage(named: "Icon_Like_Empty"), for: .normal)
        likeButton.tintColor = .gray60
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        [
            compareContainerView,
            compareBar,
            afterLabel,
            beforeLabel,
            priceLabel,
            coinLabel,
            statsStack,
            metadataCard
        ].forEach { contentView.addSubview($0) }

        compareContainerView.addSubview(compareView)
        compareBar.addSubview(compareThumb)
        statsStack.addArrangedSubview(downloadCard)
        statsStack.addArrangedSubview(likeCard)
        contentView.addSubview(likeButton)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleComparePan(_:)))
        compareBar.addGestureRecognizer(pan)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        compareContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(compareContainerView.snp.width).multipliedBy(1.05)
        }

        compareView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        compareBar.snp.makeConstraints { make in
            make.top.equalTo(compareContainerView.snp.bottom).offset(12)
            make.leading.trailing.equalTo(compareContainerView)
            make.height.equalTo(32)
        }

        compareThumb.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(32)
        }

        afterLabel.snp.makeConstraints { make in
            make.centerY.equalTo(compareBar)
            make.leading.equalTo(compareBar.snp.leading).offset(12)
        }

        beforeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(compareBar)
            make.trailing.equalTo(compareBar.snp.trailing).inset(12)
        }

        likeButton.snp.makeConstraints { make in
            make.top.equalTo(compareContainerView.snp.top).offset(12)
            make.trailing.equalTo(compareContainerView.snp.trailing).inset(12)
            make.width.height.equalTo(28)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(compareBar.snp.bottom).offset(24)
            make.leading.equalTo(compareContainerView)
        }

        coinLabel.snp.makeConstraints { make in
            make.bottom.equalTo(priceLabel.snp.bottom).offset(-4)
            make.leading.equalTo(priceLabel.snp.trailing).offset(8)
        }

        statsStack.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(16)
            make.leading.trailing.equalTo(compareContainerView)
            make.height.equalTo(70)
        }

        metadataCard.snp.makeConstraints { make in
            make.top.equalTo(statsStack.snp.bottom).offset(16)
            make.leading.trailing.equalTo(compareContainerView)
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        let input = FilterDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            likeToggle: likeToggleSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.detail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewData in
                self?.apply(viewData)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func apply(_ viewData: FilterDetailViewData) {
        navigationItem.title = viewData.title
        priceLabel.text = "\(viewData.price)"
        coinLabel.text = "Coin"
        compareView.setImages(original: viewData.originalImageURL, filtered: viewData.filteredImageURL, headers: viewData.headers)
        compareView.setProgress(compareProgress)
        downloadCard.configure(title: "다운로드", value: "\(viewData.buyerCount)+")
        likeCard.configure(title: "찜하기", value: "\(viewData.likeCount)")
        let likeIcon = viewData.isLiked ? "Icon_Like_Fill" : "Icon_Like_Empty"
        likeButton.setImage(UIImage(named: likeIcon), for: .normal)
        metadataCard.configure(
            title: viewData.metadataTitle,
            line1: viewData.metadataLine1,
            line2: viewData.metadataLine2,
            line3: viewData.metadataLine3,
            format: viewData.metadataFormat,
            latitude: viewData.latitude,
            longitude: viewData.longitude
        )
    }

    @objc private func handleComparePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: compareBar)
        let width = compareBar.bounds.width
        var centerX = compareThumb.center.x + translation.x
        centerX = max(16, min(width - 16, centerX))
        compareThumb.center.x = centerX
        gesture.setTranslation(.zero, in: compareBar)
        let progress = (centerX - 16) / (width - 32)
        compareProgress = progress
        compareView.setProgress(progress)
    }

    @objc private func likeTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        likeToggleSubject.send(())
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

private final class StatCardView: UIView {
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackTurquoise
        layer.cornerRadius = 12

        titleLabel.font = .pretendard(.medium, size: 12)
        titleLabel.textColor = .gray60

        valueLabel.font = .pretendard(.bold, size: 18)
        valueLabel.textColor = .gray30

        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

private final class MetadataCardView: UIView {
    private let headerBackground = UIView()
    private let headerStack = UIStackView()
    private let titleLabel = UILabel()
    private let formatLabel = UILabel()
    private let mapView = MKMapView()
    private let infoStack = UIStackView()
    private let line1Label = UILabel()
    private let line2Label = UILabel()
    private let line3Label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackTurquoise
        layer.cornerRadius = 12

        headerBackground.backgroundColor = .black
        headerBackground.layer.borderWidth = 3
        headerBackground.layer.borderColor = UIColor.blackTurquoise.cgColor
        headerBackground.layer.cornerRadius = 12
        headerBackground.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        addSubview(headerBackground)

        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        headerBackground.addSubview(headerStack)

        titleLabel.font = .pretendard(.bold, size: 14)
        titleLabel.textColor = .deepTurquoise
        formatLabel.font = .pretendard(.bold, size: 12)
        formatLabel.textColor = .deepTurquoise
        formatLabel.text = "EXIF"

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(formatLabel)

        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        addSubview(mapView)

        infoStack.axis = .vertical
        infoStack.spacing = 6
        addSubview(infoStack)

        line1Label.font = .pretendard(.medium, size: 12)
        line1Label.textColor = .gray75

        line2Label.font = .pretendard(.medium, size: 12)
        line2Label.textColor = .gray75

        line3Label.font = .pretendard(.regular, size: 11)
        line3Label.textColor = .gray75

        [line1Label, line2Label, line3Label].forEach { infoStack.addArrangedSubview($0) }

        headerBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }

        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(headerBackground.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(72)
            make.bottom.equalToSuperview().inset(12)
        }

        infoStack.snp.makeConstraints { make in
            make.leading.equalTo(mapView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(mapView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, line1: String, line2: String, line3: String, format: String, latitude: Double?, longitude: Double?) {
        titleLabel.text = title
        line1Label.text = line1
        line2Label.text = line2
        line3Label.text = line3
        line3Label.isHidden = line3.isEmpty
        formatLabel.text = format

        if let lat = latitude, let lon = longitude {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 250, longitudinalMeters: 250)
            mapView.setRegion(region, animated: false)
            mapView.removeAnnotations(mapView.annotations)
        }
    }
}
