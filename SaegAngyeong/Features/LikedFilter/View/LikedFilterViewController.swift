//
//  LikedFilterViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import UIKit
import SnapKit
import Combine

final class LikedFilterViewController: BaseViewController<LikedFilterViewModel> {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private var items: [LikedFilterItemViewData] = []
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let loadNextSubject = PassthroughSubject<Void, Never>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
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
        navigationController?.navigationBar.tintColor = .gray60
        navigationController?.navigationBar.barStyle = .black
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = "좋아요한 필터"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LikedFilterCell.self, forCellReuseIdentifier: LikedFilterCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 92

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .gray60
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        emptyLabel.text = "좋아요한 필터가 없습니다."
        emptyLabel.textColor = .gray75
        emptyLabel.font = .pretendard(.medium, size: 12)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(tableView)
        view.addSubview(emptyLabel)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func bindViewModel() {
        let input = LikedFilterViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher(),
            loadNext: loadNextSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
                self?.emptyLabel.isHidden = !items.isEmpty
                self?.tableView.reloadData()
                self?.tableView.refreshControl?.endRefreshing()
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.tableView.refreshControl?.endRefreshing()
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    @objc private func handleRefresh() {
        refreshSubject.send(())
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension LikedFilterViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LikedFilterCell.reuseID, for: indexPath) as? LikedFilterCell else {
            return UITableViewCell()
        }
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == tableView else { return }
        let threshold = scrollView.contentSize.height - scrollView.bounds.height - 200
        if scrollView.contentOffset.y > threshold {
            loadNextSubject.send(())
        }
    }
}

private final class LikedFilterCell: UITableViewCell {
    static let reuseID = "LikedFilterCell"

    private let cardView = UIView()
    private let thumbImageView = UIImageView()
    private let titleLabel = UILabel()
    private let creatorLabel = UILabel()
    private let likeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .blackTurquoise
        cardView.layer.cornerRadius = 16

        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 12
        thumbImageView.backgroundColor = .gray15

        titleLabel.font = .pretendard(.bold, size: 14)
        titleLabel.textColor = .gray30

        creatorLabel.font = .pretendard(.medium, size: 11)
        creatorLabel.textColor = .gray75

        likeLabel.font = .pretendard(.medium, size: 12)
        likeLabel.textColor = .brightTurquoise

        contentView.addSubview(cardView)
        cardView.addSubview(thumbImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(creatorLabel)
        cardView.addSubview(likeLabel)

        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        thumbImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(64)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(thumbImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(12)
        }

        creatorLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
        }

        likeLabel.snp.makeConstraints { make in
            make.top.equalTo(creatorLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
    }

    func configure(with item: LikedFilterItemViewData) {
        titleLabel.text = item.title
        creatorLabel.text = item.creator
        likeLabel.text = "♡ \(item.likeCountText)"
        KingfisherHelper.setImage(thumbImageView, url: item.thumbnailURL, headers: item.headers, logLabel: "liked-thumb")
    }
}
