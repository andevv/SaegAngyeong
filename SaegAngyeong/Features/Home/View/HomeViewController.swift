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

    private let authorTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 작가 소개"
        label.textColor = .gray60
        label.font = .pretendard(.bold, size: 20)
        return label
    }()

    private let authorProfileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 32
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.gray90.withAlphaComponent(0.2).cgColor
        return imageView
    }()

    private let authorNameLabel: UILabel = {
        let label = UILabel()
        label.font = .mulgyeol(.bold, size: 22)
        label.textColor = .gray30
        return label
    }()

    private let authorNickLabel: UILabel = {
        let label = UILabel()
        label.font = .pretendard(.medium, size: 14)
        label.textColor = .gray60
        return label
    }()

    private let authorIntroLabel: UILabel = {
        let label = UILabel()
        label.font = .mulgyeol(.regular, size: 14)
        label.textColor = .gray45
        label.numberOfLines = 0
        return label
    }()

    private let authorDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .pretendard(.regular, size: 12)
        label.textColor = .gray45
        label.numberOfLines = 0
        return label
    }()

    private lazy var authorFilterCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.itemSize = CGSize(width: 140, height: 100)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(AuthorFilterCell.self, forCellWithReuseIdentifier: AuthorFilterCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let tagStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fillProportionally
        stack.clipsToBounds = true
        return stack
    }()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private var categories: [CategoryViewData] = []
    private var banners: [BannerViewData] = []
    private var hotTrends: [HotTrendViewData] = []
    private var todayAuthor: TodayAuthorViewData?
    var onHotTrendSelected: ((String) -> Void)?

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
            hotTrendCollectionView,
            authorTitleLabel,
            authorProfileImageView,
            authorNameLabel,
            authorNickLabel,
            authorFilterCollectionView,
            tagStackView,
            authorIntroLabel,
            authorDescriptionLabel
        ].forEach { contentView.addSubview($0) }
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview() // 상단 safe area 무시
            make.bottom.equalTo(view.safeAreaLayoutGuide) // 하단 safe area는 준수
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
            make.top.equalTo(bannerCollectionView.snp.bottom).offset(36)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        hotTrendCollectionView.snp.makeConstraints { make in
            make.top.equalTo(hotTrendTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(340)
        }

        authorTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(hotTrendCollectionView.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        authorProfileImageView.snp.makeConstraints { make in
            make.top.equalTo(authorTitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(64)
        }
        authorNameLabel.snp.makeConstraints { make in
            make.top.equalTo(authorProfileImageView.snp.top).offset(4)
            make.leading.equalTo(authorProfileImageView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }
        authorNickLabel.snp.makeConstraints { make in
            make.top.equalTo(authorNameLabel.snp.bottom).offset(4)
            make.leading.equalTo(authorNameLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }

        authorFilterCollectionView.snp.makeConstraints { make in
            make.top.equalTo(authorProfileImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }

        tagStackView.snp.makeConstraints { make in
            make.top.equalTo(authorFilterCollectionView.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(24)
        }

        authorIntroLabel.snp.makeConstraints { make in
            make.top.equalTo(tagStackView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        authorDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(authorIntroLabel.snp.bottom).offset(12)
            make.leading.trailing.equalTo(authorIntroLabel)
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
                KingfisherHelper.setImage(self?.backgroundImageView ?? UIImageView(), url: viewData.imageURL, headers: viewData.headers, logLabel: "highlight")
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

        output.todayAuthor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] author in
                self?.todayAuthor = author
                self?.apply(author: author)
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func apply(author: TodayAuthorViewData) {
        authorNameLabel.text = author.name
        authorNickLabel.text = author.nick
        authorIntroLabel.text = author.introduction
        authorDescriptionLabel.text = author.description

        // tags
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tag in author.tags {
            let label = PaddingLabel(padding: UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10))
            label.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            label.textColor = .gray45
            label.font = .pretendard(.medium, size: 12)
            label.layer.cornerRadius = 12
            label.clipsToBounds = true
            label.text = tag
            tagStackView.addArrangedSubview(label)
        }

        authorFilterCollectionView.reloadData()

        // profile image
        if let url = author.profileImageURL {
            KingfisherHelper.setImage(authorProfileImageView, url: url, headers: author.headers, logLabel: "author-profile")
        } else {
            authorProfileImageView.image = nil
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

    private func openBannerIfNeeded(_ banner: BannerViewData) {
        guard
            banner.payloadType?.uppercased() == "WEBVIEW",
            let url = banner.linkURL
        else { return }

        let webVC = WebViewController(
            url: url,
            sesacKey: AppConfig.apiKey,
            accessTokenProvider: { [weak self] in self?.viewModel.currentAccessToken }
        )
        webVC.modalPresentationStyle = .fullScreen
        present(webVC, animated: true)
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
        if collectionView == authorFilterCollectionView {
            return todayAuthor?.filters.count ?? 0
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
        if collectionView == authorFilterCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AuthorFilterCell.reuseID, for: indexPath) as! AuthorFilterCell
            if let data = todayAuthor?.filters[indexPath.item] {
                cell.configure(with: data)
            }
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
            openBannerIfNeeded(banner)
        } else if collectionView == authorFilterCollectionView {
            if let item = todayAuthor?.filters[indexPath.item] {
                print("[Home] author filter tapped:", item.title)
            }
        } else {
            let item = hotTrends[indexPath.item]
            print("[Home] hot trend tapped:", item.title)
            onHotTrendSelected?(item.id)
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
