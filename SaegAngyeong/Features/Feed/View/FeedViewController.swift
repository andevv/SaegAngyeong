//
//  FeedViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/21/25.
//

import UIKit
import SnapKit
import Combine

final class FeedViewController: BaseViewController<FeedViewModel> {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Top Ranking"
        label.textColor = .gray60
        label.font = .pretendard(.bold, size: 18)
        return label
    }()

    private let orderStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var rankingCollectionView: UICollectionView = {
        let layout = FeedViewController.makeRankingLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.register(FeedRankCell.self, forCellWithReuseIdentifier: FeedRankCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private let emptyStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Feed_Empty"))
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.8
        imageView.isHidden = true
        return imageView
    }()

    private let feedSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Filter Feed"
        label.textColor = .gray60
        label.font = .pretendard(.bold, size: 18)
        return label
    }()

    private let feedModeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("List Mode", for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 12)
        button.tintColor = .gray75
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        button.layer.cornerRadius = 0
        button.layer.borderWidth = 0
        return button
    }()

    private lazy var feedCollectionView: UICollectionView = {
        let layout = makeFeedLayout(for: .list)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(FeedListCell.self, forCellWithReuseIdentifier: FeedListCell.reuseID)
        collectionView.register(FeedBlockCell.self, forCellWithReuseIdentifier: FeedBlockCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private var orderButtons: [FeedOrder: UIButton] = [:]
    private var rankingItems: [FeedRankViewData] = []
    private var feedItems: [FeedItemViewData] = []
    private var feedLayoutMode: FeedLayoutMode = .list
    private var feedCollectionHeightConstraint: Constraint?

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let orderSelectionSubject = PassthroughSubject<FeedOrder, Never>()
    private let loadNextPageSubject = PassthroughSubject<Void, Never>()
    private let likeToggleSubject = PassthroughSubject<FeedLikeAction, Never>()

    override init(viewModel: FeedViewModel) {
        super.init(viewModel: viewModel)
        tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "Feed_Empty"),
            selectedImage: UIImage(named: "Feed_Fill")
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationController?.navigationBar.barStyle = .black
        viewDidLoadSubject.send(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.gray60
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray60
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateFeedCollectionHeight()
    }

    override func configureUI() {
        let navTitleLabel = UILabel()
        navTitleLabel.text = "FEED"
        navTitleLabel.textColor = .gray60
        navTitleLabel.font = .mulgyeol(.bold, size: 20)
        navigationItem.titleView = navTitleLabel

        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            titleLabel,
            orderStackView,
            rankingCollectionView,
            emptyStateImageView,
            feedSectionLabel,
            feedModeButton,
            feedCollectionView
        ].forEach { contentView.addSubview($0) }

        FeedOrder.allCases.forEach { order in
            let button = makeOrderButton(title: order.title)
            button.tag = orderButtonTag(for: order)
            button.addTarget(self, action: #selector(orderButtonTapped(_:)), for: .touchUpInside)
            orderButtons[order] = button
            orderStackView.addArrangedSubview(button)
        }

        feedModeButton.addTarget(self, action: #selector(feedModeTapped), for: .touchUpInside)
        applyFeedMode(.list)
    }

    override func configureLayout() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().inset(20)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        orderStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }

        rankingCollectionView.snp.makeConstraints { make in
            make.top.equalTo(orderStackView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(480)
        }

        emptyStateImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(rankingCollectionView.snp.centerY)
            make.width.equalToSuperview().multipliedBy(0.55)
            make.height.equalTo(emptyStateImageView.snp.width)
        }

        feedSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(rankingCollectionView.snp.bottom).offset(24)
            make.leading.equalToSuperview().inset(20)
        }

        feedModeButton.snp.makeConstraints { make in
            make.centerY.equalTo(feedSectionLabel)
            make.trailing.equalToSuperview().inset(20)
        }

        feedCollectionView.snp.makeConstraints { make in
            make.top.equalTo(feedSectionLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            feedCollectionHeightConstraint = make.height.equalTo(200).constraint
            make.bottom.equalToSuperview().offset(-24)
        }
    }

    override func bindViewModel() {
        let input = FeedViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            orderSelection: orderSelectionSubject.eraseToAnyPublisher(),
            loadNextPage: loadNextPageSubject.eraseToAnyPublisher(),
            likeToggle: likeToggleSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.selectedOrder
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                self?.applySelectedOrder(order)
            }
            .store(in: &cancellables)

        output.rankings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.rankingItems = items
                self?.rankingCollectionView.reloadData()
                self?.emptyStateImageView.isHidden = !items.isEmpty
                self?.rankingCollectionView.collectionViewLayout.invalidateLayout()
                self?.rankingCollectionView.layoutIfNeeded()
                if !items.isEmpty {
                    self?.rankingCollectionView.scrollToItem(
                        at: IndexPath(item: 0, section: 0),
                        at: .centeredHorizontally,
                        animated: false
                    )
                }
            }
            .store(in: &cancellables)

        output.feedItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.feedItems = items
                self?.feedCollectionView.collectionViewLayout.invalidateLayout()
                self?.feedCollectionView.reloadData()
                self?.updateFeedCollectionHeight()
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func makeOrderButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 13)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray75.cgColor
        button.setTitleColor(.gray45, for: .normal)
        button.backgroundColor = .gray90
        return button
    }

    private func makeFeedLayout(for mode: FeedLayoutMode) -> UICollectionViewLayout {
        switch mode {
        case .list:
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            return layout
        case .block:
            let layout = FeedMasonryLayout()
            layout.numberOfColumns = 2
            layout.cellPadding = 12
            layout.verticalPadding = 0
            layout.delegate = self
            return layout
        }
    }

    private func applyFeedMode(_ mode: FeedLayoutMode) {
        feedLayoutMode = mode
        let isList = mode == .list
        let title = isList ? "List Mode" : "Block Mode"
        feedModeButton.setTitle(title, for: .normal)
        feedModeButton.setTitleColor(.gray60, for: .normal)
        feedModeButton.backgroundColor = .clear
        feedCollectionView.setCollectionViewLayout(makeFeedLayout(for: mode), animated: false)
        feedCollectionView.collectionViewLayout.invalidateLayout()
        feedCollectionView.reloadData()
        updateFeedCollectionHeight()
    }

    private func updateFeedCollectionHeight() {
        feedCollectionView.layoutIfNeeded()
        let height = feedCollectionView.collectionViewLayout.collectionViewContentSize.height
        if let current = feedCollectionHeightConstraint?.layoutConstraints.first?.constant, abs(current - height) < 1 {
            return
        }
        feedCollectionHeightConstraint?.update(offset: max(1, height))
        view.layoutIfNeeded()
    }

    private func applySelectedOrder(_ order: FeedOrder) {
        orderButtons.forEach { entry in
            let isSelected = entry.key == order
            let button = entry.value
            button.backgroundColor = isSelected ? .brightTurquoise : .blackTurquoise
            button.setTitleColor(isSelected ? .gray45 : .gray75, for: .normal)
            button.layer.borderColor = (isSelected ? UIColor.clear : UIColor.blackTurquoise).cgColor
        }
    }

    private func orderButtonTag(for order: FeedOrder) -> Int {
        switch order {
        case .popularity: return 0
        case .purchase: return 1
        case .latest: return 2
        }
    }

    private func orderForButtonTag(_ tag: Int) -> FeedOrder? {
        switch tag {
        case 0: return .popularity
        case 1: return .purchase
        case 2: return .latest
        default: return nil
        }
    }

    @objc private func orderButtonTapped(_ sender: UIButton) {
        guard let order = orderForButtonTag(sender.tag) else { return }
        orderSelectionSubject.send(order)
    }

    @objc private func feedModeTapped() {
        applyFeedMode(feedLayoutMode == .list ? .block : .list)
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private static func makeRankingLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { _, layoutEnvironment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.6),
                heightDimension: .absolute(480)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.interGroupSpacing = 16
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            section.visibleItemsInvalidationHandler = { items, offset, environment in
                let containerWidth = environment.container.effectiveContentSize.width
                let centerX = offset.x + containerWidth / 2
                let maxDistance = containerWidth * 0.6
                items.forEach { item in
                    guard item.representedElementCategory == .cell else { return }
                    let distance = abs(item.center.x - centerX)
                    let progress = max(0, 1 - (distance / maxDistance))
                    let lift = 40 * progress
                    item.transform = CGAffineTransform(translationX: 0, y: -lift)
                    item.zIndex = Int(progress * 10)
                }
            }
            return section
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }

}

private enum FeedLayoutMode {
    case list
    case block
}

// MARK: - CollectionView

extension FeedViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == rankingCollectionView {
            return rankingItems.count
        }
        return feedItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == rankingCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedRankCell.reuseID, for: indexPath) as! FeedRankCell
            cell.configure(with: rankingItems[indexPath.item])
            return cell
        }
        if feedLayoutMode == .list {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedListCell.reuseID, for: indexPath) as! FeedListCell
            let item = feedItems[indexPath.item]
            cell.configure(with: item)
            cell.onLikeTap = { [weak self] in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                self?.likeToggleSubject.send(FeedLikeAction(filterID: item.id))
            }
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedBlockCell.reuseID, for: indexPath) as! FeedBlockCell
        let item = feedItems[indexPath.item]
        cell.configure(with: item)
        cell.onLikeTap = { [weak self] in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            self?.likeToggleSubject.send(FeedLikeAction(filterID: item.id))
        }
        return cell
    }

}

extension FeedViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard collectionView == feedCollectionView, feedLayoutMode == .list else {
            return CGSize(width: 10, height: 10)
        }
        let width = collectionView.bounds.width - 40
        return CGSize(width: width, height: 128)
    }
}

extension FeedViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        let threshold = scrollView.contentSize.height - scrollView.bounds.height - 200
        if scrollView.contentOffset.y > threshold {
            loadNextPageSubject.send(())
        }
    }
}

extension FeedViewController: FeedMasonryLayoutDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {
        guard collectionView == feedCollectionView else { return 180 }
        return feedItems[indexPath.item].masonryHeight + 32
    }
}
