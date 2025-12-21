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

    private var orderButtons: [FeedOrder: UIButton] = [:]
    private var rankingItems: [FeedRankViewData] = []

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let orderSelectionSubject = PassthroughSubject<FeedOrder, Never>()

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
        viewDidLoadSubject.send(())
    }

    override func configureUI() {
        view.addSubview(titleLabel)
        view.addSubview(orderStackView)
        view.addSubview(rankingCollectionView)
        view.addSubview(emptyStateImageView)

        FeedOrder.allCases.forEach { order in
            let button = makeOrderButton(title: order.title)
            button.tag = orderButtonTag(for: order)
            button.addTarget(self, action: #selector(orderButtonTapped(_:)), for: .touchUpInside)
            orderButtons[order] = button
            orderStackView.addArrangedSubview(button)
        }
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
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
            make.height.equalTo(500)
        }

        emptyStateImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(rankingCollectionView.snp.centerY)
            make.width.equalToSuperview().multipliedBy(0.55)
            make.height.equalTo(emptyStateImageView.snp.width)
        }
    }

    override func bindViewModel() {
        let input = FeedViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            orderSelection: orderSelectionSubject.eraseToAnyPublisher()
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

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private static func makeRankingLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.65),
                heightDimension: .absolute(500)
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

extension FeedViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rankingItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedRankCell.reuseID, for: indexPath) as! FeedRankCell
        cell.configure(with: rankingItems[indexPath.item])
        return cell
    }

}

// MARK: - Feed Rank Cell

private final class FeedRankCell: UICollectionViewCell {
    static let reuseID = "FeedRankCell"

    private let containerView = UIView()
    private let imageContainerView = UIView()
    private let imageView = UIImageView()
    private let creatorLabel = UILabel()
    private let titleLabel = UILabel()
    private let categoryLabel = UILabel()
    private let rankBadgeView = UIView()
    private let rankLabel = UILabel()
    private let shadowView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        shadowView.backgroundColor = .clear
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.35
        shadowView.layer.shadowRadius = 16
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 10)
        contentView.addSubview(shadowView)

        containerView.backgroundColor = .blackTurquoise
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.gray75.withAlphaComponent(0.25).cgColor
        containerView.clipsToBounds = true
        shadowView.addSubview(containerView)

        imageContainerView.backgroundColor = .clear
        imageContainerView.layer.borderWidth = 0
        imageContainerView.clipsToBounds = true
        containerView.addSubview(imageContainerView)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageContainerView.addSubview(imageView)

        creatorLabel.font = .pretendard(.medium, size: 12)
        creatorLabel.textColor = .gray60
        creatorLabel.textAlignment = .center
        containerView.addSubview(creatorLabel)

        titleLabel.font = .mulgyeol(.bold, size: 24)
        titleLabel.textColor = .gray30
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        categoryLabel.font = .pretendard(.medium, size: 12)
        categoryLabel.textColor = .gray60
        categoryLabel.textAlignment = .center
        containerView.addSubview(categoryLabel)

        rankBadgeView.backgroundColor = UIColor.gray90.withAlphaComponent(0.9)
        rankBadgeView.layer.borderWidth = 1
        rankBadgeView.layer.borderColor = UIColor.gray75.withAlphaComponent(0.5).cgColor
        contentView.addSubview(rankBadgeView)

        rankLabel.font = .mulgyeol(.bold, size: 18)
        rankLabel.textColor = .deepTurquoise
        rankLabel.textAlignment = .center
        rankBadgeView.addSubview(rankLabel)

        shadowView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(44)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(28)
        }

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        imageContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(250)
        }

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        creatorLabel.snp.makeConstraints { make in
            make.top.equalTo(imageContainerView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(creatorLabel.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(24)
        }

        rankBadgeView.snp.makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.centerY.equalTo(containerView.snp.bottom)
            make.width.height.equalTo(44)
        }

        rankLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        setNeedsLayout()
        layoutIfNeeded()
        updateCorners()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorners()
    }

    func configure(with data: FeedRankViewData) {
        creatorLabel.text = data.creatorNick.uppercased()
        titleLabel.text = data.title
        categoryLabel.text = "#\(data.category)"
        rankLabel.text = "\(data.rank)"

        if let url = data.imageURL {
            KingfisherHelper.setImage(imageView, url: url, headers: data.headers, logLabel: "feed-rank")
        } else {
            imageView.image = UIImage(named: "Filter_Empty")
        }
    }

    private func updateCorners() {
        imageContainerView.layer.cornerRadius = imageContainerView.bounds.width / 2
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        rankBadgeView.layer.cornerRadius = rankBadgeView.bounds.width / 2
        let capsuleRadius = min(containerView.bounds.width, containerView.bounds.height) / 2
        containerView.layer.cornerRadius = capsuleRadius
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: capsuleRadius).cgPath
    }
}
