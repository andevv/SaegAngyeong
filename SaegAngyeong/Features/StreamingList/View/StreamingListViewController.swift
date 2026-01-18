//
//  StreamingListViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import UIKit
import SnapKit
import Combine
import Kingfisher

final class StreamingListViewController: BaseViewController<StreamingListViewModel> {
    var onVideoSelected: ((String, String, String, String) -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    private var items: [StreamingListItemViewData] = []
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private let loadNextSubject = PassthroughSubject<Void, Never>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        viewDidLoadSubject.send(())
    }

    override func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = "STREAMING"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.register(StreamingListCell.self, forCellReuseIdentifier: StreamingListCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self

        refreshControl.tintColor = .gray60
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(tableView)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func bindViewModel() {
        let input = StreamingListViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher(),
            loadNext: loadNextSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.items = items
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.refreshControl.endRefreshing()
                self?.presentError(error)
            }
            .store(in: &cancellables)

        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading == false {
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .networkRetryRequested)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSubject.send(())
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

extension StreamingListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StreamingListCell.reuseID, for: indexPath) as? StreamingListCell else {
            return UITableViewCell()
        }
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        onVideoSelected?(item.id, item.title, item.viewCountText, item.likeCountText)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let threshold = scrollView.contentSize.height - scrollView.bounds.height - 120
        if offsetY > threshold {
            loadNextSubject.send(())
        }
    }
}

private final class StreamingListCell: UITableViewCell {
    static let reuseID = "StreamingListCell"

    private let thumbnailView = UIImageView()
    private let durationLabel = PaddingLabel(padding: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.layer.cornerRadius = 12
        thumbnailView.backgroundColor = .blackTurquoise

        durationLabel.font = .pretendard(.medium, size: 11)
        durationLabel.textColor = .gray30
        durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        durationLabel.layer.cornerRadius = 8
        durationLabel.clipsToBounds = true
        durationLabel.textAlignment = .center

        titleLabel.font = .pretendard(.medium, size: 14)
        titleLabel.textColor = .gray30
        titleLabel.numberOfLines = 2

        descriptionLabel.font = .pretendard(.regular, size: 12)
        descriptionLabel.textColor = .gray60
        descriptionLabel.numberOfLines = 2

        statLabel.font = .pretendard(.regular, size: 11)
        statLabel.textColor = .gray75

        contentView.addSubview(thumbnailView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(statLabel)
        thumbnailView.addSubview(durationLabel)

        thumbnailView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(140)
            make.height.equalTo(80)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }

        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
            make.width.greaterThanOrEqualTo(40)
            make.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailView)
            make.leading.equalTo(thumbnailView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }

        statLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: StreamingListItemViewData) {
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        durationLabel.text = item.durationText
        statLabel.text = "\(item.viewCountText) · \(item.likeCountText)"
        KingfisherHelper.setImage(
            thumbnailView,
            url: item.thumbnailURL,
            headers: item.headers,
            placeholder: UIImage(named: "Profile_Empty"),
            logLabel: "streaming-thumb"
        )
    }
}
