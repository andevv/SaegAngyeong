//
//  MyUploadViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/3/26.
//

import UIKit
import SnapKit
import Combine

final class MyUploadViewController: BaseViewController<MyUploadViewModel> {
    var onFilterSelected: ((String) -> Void)?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    private var items: [MyUploadItemViewData] = []
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshSubject.send(())
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = "내가 만든 필터"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        tableView.backgroundColor = .black
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MyUploadCell.self, forCellReuseIdentifier: MyUploadCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 92

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .gray60
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        emptyLabel.text = "내가 만든 필터가 없습니다."
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
        let input = MyUploadViewModel.Input(
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

extension MyUploadViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MyUploadCell.reuseID, for: indexPath) as? MyUploadCell else {
            return UITableViewCell()
        }
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        onFilterSelected?(item.id)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == tableView else { return }
        let threshold = scrollView.contentSize.height - scrollView.bounds.height - 200
        if scrollView.contentOffset.y > threshold {
            loadNextSubject.send(())
        }
    }
}
