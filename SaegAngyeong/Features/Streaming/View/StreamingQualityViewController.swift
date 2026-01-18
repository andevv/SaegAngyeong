//
//  StreamingQualityViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/18/26.
//

import UIKit
import SnapKit

final class StreamingQualityViewController: UIViewController {
    private let options: [String]
    private let selected: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let titleLabel = UILabel()

    var onSelected: ((String) -> Void)?

    init(options: [String], selected: String) {
        self.options = options
        self.selected = selected
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blackTurquoise

        titleLabel.text = "화질 선택"
        titleLabel.font = .pretendard(.medium, size: 14)
        titleLabel.textColor = .gray60
        titleLabel.textAlignment = .center

        tableView.backgroundColor = .blackTurquoise
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.06)
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "QualityCell")

        view.addSubview(titleLabel)
        view.addSubview(tableView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension StreamingQualityViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QualityCell", for: indexPath)
        let option = options[indexPath.row]
        cell.backgroundColor = .blackTurquoise
        cell.textLabel?.text = option
        cell.textLabel?.font = .pretendard(.regular, size: 14)
        cell.textLabel?.textColor = .gray30
        cell.accessoryType = option == selected ? .checkmark : .none
        cell.tintColor = .brightTurquoise
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        onSelected?(option)
        dismiss(animated: true)
    }
}
