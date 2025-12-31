//
//  PurchaseHistoryViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import UIKit
import SnapKit
import Combine

final class PurchaseHistoryViewController: BaseViewController<PurchaseHistoryViewModel> {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private var items: [PurchaseHistoryItemViewData] = []
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()

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
        titleLabel.text = "구매내역"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PurchaseHistoryCell.self, forCellReuseIdentifier: PurchaseHistoryCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 92

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .gray60
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        emptyLabel.text = "구매내역이 없습니다."
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
        let input = PurchaseHistoryViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            refresh: refreshSubject.eraseToAnyPublisher()
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

extension PurchaseHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PurchaseHistoryCell.reuseID, for: indexPath) as? PurchaseHistoryCell else {
            return UITableViewCell()
        }
        cell.configure(with: items[indexPath.row])
        return cell
    }
}

private final class PurchaseHistoryCell: UITableViewCell {
    static let reuseID = "PurchaseHistoryCell"

    private let cardView = UIView()
    private let thumbImageView = UIImageView()
    private let titleLabel = UILabel()
    private let creatorLabel = UILabel()
    private let priceLabel = UILabel()
    private let dateLabel = UILabel()

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

        priceLabel.font = .pretendard(.bold, size: 12)
        priceLabel.textColor = .brightTurquoise

        dateLabel.font = .pretendard(.regular, size: 11)
        dateLabel.textColor = .gray60

        contentView.addSubview(cardView)
        cardView.addSubview(thumbImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(creatorLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(dateLabel)

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

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(creatorLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(14)
        }

        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(priceLabel)
            make.trailing.equalToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
    }

    func configure(with item: PurchaseHistoryItemViewData) {
        titleLabel.text = item.title
        creatorLabel.text = item.creator
        priceLabel.text = item.priceText
        dateLabel.text = item.paidAtText
        if let url = item.thumbnailURL {
            KingfisherHelper.setImage(thumbImageView, url: url, headers: [:], logLabel: "purchase-thumb")
        } else {
            thumbImageView.image = UIImage(named: "Home_Empty")
        }
    }
}
