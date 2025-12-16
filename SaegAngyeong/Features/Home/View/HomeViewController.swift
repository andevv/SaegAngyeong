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

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let overlayGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.black.withAlphaComponent(0.95).cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor
        ]
        layer.locations = [0.0, 0.7, 1.0]
        layer.startPoint = CGPoint(x: 0.5, y: 1.0)   // 이미지뷰 하단부터 시작
        layer.endPoint = CGPoint(x: 0.5, y: 0.0)     // 위로 서서히 투명
        return layer
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray60
        label.font = .pretendard(.medium, size: 13)
        label.text = "오늘의 필터 소개"
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray30
        label.font = .mulgyeol(.bold, size: 32)
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray60
        label.font = .pretendard(.regular, size: 12)
        label.numberOfLines = 0
        return label
    }()

    private let useButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("사용해보기", for: .normal)
        button.setTitleColor(.gray45, for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 12)
        button.backgroundColor = .gray15.withAlphaComponent(0.1)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        button.layer.borderWidth = 0.5
        return button
    }()

    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        layout.itemSize = CGSize(width: 80, height: 72)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var bannerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.itemSize = CGSize(width: view.bounds.width - 32, height: 140)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = .clear
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPage = 0
        control.currentPageIndicatorTintColor = .white
        control.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        return control
    }()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private var categories: [CategoryViewData] = []
    private var banners: [BannerViewData] = []

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
        view.backgroundColor = .black
        viewDidLoadSubject.send(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        overlayGradient.frame = backgroundImageView.bounds
        // 카테고리 버튼 5개가 한 화면에 고정되도록 아이템 사이즈 계산
        if let layout = categoryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let availableWidth = categoryCollectionView.bounds.width
            let inset = layout.sectionInset.left + layout.sectionInset.right
            let spacing = layout.minimumInteritemSpacing * 4
            if availableWidth > 0 {
                let width = (availableWidth - inset - spacing) / 5
                layout.itemSize = CGSize(width: width, height: 72)
                layout.invalidateLayout()
            }
        }
        if let layout = bannerCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let inset = layout.sectionInset.left + layout.sectionInset.right
            layout.itemSize = CGSize(width: view.bounds.width - inset, height: 140)
            layout.invalidateLayout()
        }
    }

    override func configureUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(overlayGradient)

        [subtitleLabel, titleLabel, descriptionLabel, useButton, categoryCollectionView, bannerCollectionView, pageControl].forEach { contentView.addSubview($0) }
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // safe area 무시하고 전체 영역 사용
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        backgroundImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(view.snp.width).multipliedBy(1.3)
        }

        useButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(70)
            make.trailing.equalToSuperview().inset(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(backgroundImageView.snp.bottom).inset(180)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalTo(titleLabel.snp.top).offset(-12)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
        }

        categoryCollectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(92)
            make.bottom.equalTo(backgroundImageView.snp.bottom).offset(-24)
        }

        bannerCollectionView.snp.makeConstraints { make in
            make.top.equalTo(backgroundImageView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(160)
            make.bottom.equalToSuperview().offset(-24)
        }

        pageControl.snp.makeConstraints { make in
            make.trailing.equalTo(bannerCollectionView.snp.trailing).inset(12)
            make.bottom.equalTo(bannerCollectionView.snp.bottom).inset(8)
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

        output.categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                self?.categories = categories
                self?.categoryCollectionView.reloadData()
            }
            .store(in: &cancellables)

        output.banners
            .receive(on: DispatchQueue.main)
            .sink { [weak self] banners in
                self?.banners = banners
                self?.pageControl.numberOfPages = banners.count
                self?.bannerCollectionView.reloadData()
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
        guard let url else {
            backgroundImageView.image = nil
            return
        }
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

// MARK: - CollectionView

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView {
            return categories.count
        }
        return banners.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseID, for: indexPath) as! CategoryCell
            cell.configure(with: categories[indexPath.item])
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.reuseID, for: indexPath) as! BannerCell
        cell.configure(with: banners[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            let category = categories[indexPath.item]
            print("[Home] category tapped:", category.title)
        } else {
            let banner = banners[indexPath.item]
            print("[Home] banner tapped:", banner.title)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == bannerCollectionView else { return }
        let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        pageControl.currentPage = page
    }
}

// MARK: - Cells

private final class CategoryCell: UICollectionViewCell {
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

private final class BannerCell: UICollectionViewCell {
    static let reuseID = "BannerCell"

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)
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
