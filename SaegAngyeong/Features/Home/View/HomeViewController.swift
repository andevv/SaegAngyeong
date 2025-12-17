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
        let layout = HomeViewController.makeBannerLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast
        collectionView.backgroundColor = .clear
        collectionView.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let pageLabel: PaddingLabel = {
        let label = PaddingLabel(padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        label.backgroundColor = .gray60.withAlphaComponent(0.2)
        label.textColor = .gray45
        label.font = .pretendard(.medium, size: 10)
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor.gray60.cgColor
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.text = "0/0"
        return label
    }()

    private let hotTrendTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "핫 트렌드"
        label.textColor = .gray60
        label.font = .pretendard(.bold, size: 20)
        return label
    }()

    private lazy var hotTrendCollectionView: UICollectionView = {
        let layout = HomeViewController.makeHotTrendLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.isDirectionalLockEnabled = true
        collectionView.isScrollEnabled = false // 수직 스크롤 방지, 부모 스크롤뷰만 세로 스크롤
        collectionView.backgroundColor = .clear
        collectionView.register(HotTrendCell.self, forCellWithReuseIdentifier: HotTrendCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private var categories: [CategoryViewData] = []
    private var banners: [BannerViewData] = []
    private var hotTrends: [HotTrendViewData] = []

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

        // 배너가 좌우 패딩을 포함한 한 페이지에 한 개씩 보이도록 사이즈 재계산
        if let layout = bannerCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let horizontalInset = layout.sectionInset.left + layout.sectionInset.right
            let width = bannerCollectionView.bounds.width - horizontalInset
            if width > 0 {
                layout.itemSize = CGSize(width: width, height: 120)
                layout.invalidateLayout()
            }
        }

    }

    override func configureUI() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(backgroundImageView)
        backgroundImageView.layer.addSublayer(overlayGradient)

        [
            subtitleLabel,
            titleLabel,
            descriptionLabel,
            useButton,
            categoryCollectionView,
            bannerCollectionView,
            pageLabel,
            hotTrendTitleLabel,
            hotTrendCollectionView
        ].forEach { contentView.addSubview($0) }
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
            make.top.equalTo(backgroundImageView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }

        pageLabel.snp.makeConstraints { make in
            make.trailing.equalTo(bannerCollectionView.snp.trailing).inset(24)
            make.bottom.equalTo(bannerCollectionView.snp.bottom).inset(12)
        }

        hotTrendTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(bannerCollectionView.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        hotTrendCollectionView.snp.makeConstraints { make in
            make.top.equalTo(hotTrendTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(340)
            make.bottom.equalToSuperview().offset(-24)
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
                self?.updatePageLabel(current: 0, total: banners.count)
                self?.bannerCollectionView.reloadData()
            }
            .store(in: &cancellables)

        output.hotTrends
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.hotTrends = items
                self?.hotTrendCollectionView.reloadData()
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

    private func updatePageLabel(current: Int, total: Int) {
        guard total > 0 else {
            pageLabel.text = "0/0"
            return
        }
        pageLabel.text = "\(current + 1) / \(total)"
    }

    private func currentBannerPage() -> Int {
        guard
            let layout = bannerCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
            banners.count > 0
        else { return 0 }

        let pageWidth = layout.itemSize.width + layout.minimumLineSpacing
        let offsetX = bannerCollectionView.contentOffset.x
        let page = max(0, min(CGFloat(banners.count - 1), round(offsetX / pageWidth)))
        return Int(page)
    }

    private static func makeBannerLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        let width = UIScreen.main.bounds.width - layout.sectionInset.left - layout.sectionInset.right
        layout.itemSize = CGSize(width: width, height: 120)
        return layout
    }

    private static func makeHotTrendLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // 세로로 긴 카드, 좌우 패딩 포함 한 장씩 페이징
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.65),
                heightDimension: .absolute(300)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.interGroupSpacing = 16
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
}

// MARK: - CollectionView

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView {
            return categories.count
        }
        if collectionView == bannerCollectionView {
            return banners.count
        }
        return hotTrends.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseID, for: indexPath) as! CategoryCell
            cell.configure(with: categories[indexPath.item])
            return cell
        }
        if collectionView == bannerCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.reuseID, for: indexPath) as! BannerCell
            cell.configure(with: banners[indexPath.item])
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HotTrendCell.reuseID, for: indexPath) as! HotTrendCell
        cell.configure(with: hotTrends[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            let category = categories[indexPath.item]
            print("[Home] category tapped:", category.title)
        } else if collectionView == bannerCollectionView {
            let banner = banners[indexPath.item]
            print("[Home] banner tapped:", banner.title)
        } else {
            let item = hotTrends[indexPath.item]
            print("[Home] hot trend tapped:", item.title)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == bannerCollectionView else { return }
        updatePageLabel(current: currentBannerPage(), total: banners.count)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == bannerCollectionView, decelerate == false else { return }
        updatePageLabel(current: currentBannerPage(), total: banners.count)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView, scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0 // 상단 바운스 제거
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard
            scrollView == bannerCollectionView,
            let layout = bannerCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
            banners.count > 0
        else { return }

        let pageWidth = layout.itemSize.width + layout.minimumLineSpacing
        let rawPage = scrollView.contentOffset.x / pageWidth

        let targetPage: CGFloat
        if velocity.x > 0 {
            targetPage = floor(rawPage + 1)
        } else if velocity.x < 0 {
            targetPage = ceil(rawPage - 1)
        } else {
            targetPage = round(rawPage)
        }

        let clampedPage = max(0, min(CGFloat(banners.count - 1), targetPage))
        let targetX = clampedPage * pageWidth
        targetContentOffset.pointee = CGPoint(x: targetX, y: 0)

        DispatchQueue.main.async { [weak self] in
            self?.updatePageLabel(current: Int(clampedPage), total: self?.banners.count ?? 0)
        }
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

private final class HotTrendCell: UICollectionViewCell {
    static let reuseID = "HotTrendCell"

    private let containerView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let likeStack = UIStackView()
    private let likeIcon = UIImageView()
    private let likeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear

        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        containerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.font = .mulgyeol(.regular, size: 14)
        titleLabel.textColor = .gray30
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().inset(12)
        }

        likeIcon.image = UIImage(systemName: "heart.fill")
        likeIcon.tintColor = .gray30
        likeLabel.font = .pretendard(.medium, size: 12)
        likeLabel.textColor = .gray30
        likeStack.axis = .horizontal
        likeStack.spacing = 4
        likeStack.alignment = .center
        likeStack.addArrangedSubview(likeIcon)
        likeStack.addArrangedSubview(likeLabel)
        containerView.addSubview(likeStack)
        likeStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: HotTrendViewData) {
        titleLabel.text = data.title
        likeLabel.text = "\(data.likeCount)"

        let modifier = AnyModifier { request in
            var r = request
            data.headers.forEach { key, value in r.setValue(value, forHTTPHeaderField: key) }
            return r
        }
        if let url = data.imageURL {
            imageView.kf.setImage(with: url, options: [.requestModifier(modifier)])
        } else {
            imageView.image = nil
        }
    }
}
