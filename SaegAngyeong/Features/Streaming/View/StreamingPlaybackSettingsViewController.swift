//
//  StreamingPlaybackSettingsViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/18/26.
//

import UIKit
import SnapKit

struct StreamingPlaybackSpeedOption {
    let label: String
    let rate: Float
}

final class StreamingPlaybackSettingsViewController: UIViewController {
    private let speedOptions: [StreamingPlaybackSpeedOption]
    private var selectedSpeed: Float
    private let qualityOptions: [String]
    private var selectedQuality: String

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let titleLabel = UILabel()

    var onSpeedSelected: ((Float) -> Void)?
    var onQualitySelected: ((String) -> Void)?

    init(
        speedOptions: [StreamingPlaybackSpeedOption],
        selectedSpeed: Float,
        qualityOptions: [String],
        selectedQuality: String
    ) {
        self.speedOptions = speedOptions
        self.selectedSpeed = selectedSpeed
        self.qualityOptions = qualityOptions
        self.selectedQuality = selectedQuality
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
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true

        titleLabel.text = "재생 설정"
        titleLabel.font = .pretendard(.medium, size: 14)
        titleLabel.textColor = .gray60
        titleLabel.textAlignment = .center

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.06)
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceHorizontal = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaybackSettingsCell")

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

extension StreamingPlaybackSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? speedOptions.count : qualityOptions.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        let label = UILabel()
        label.font = .pretendard(.medium, size: 12)
        label.textColor = .gray60
        label.text = section == 0 ? "재생 속도" : "화질"
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-6)
        }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        28
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaybackSettingsCell", for: indexPath)
        cell.backgroundColor = .blackTurquoise
        cell.textLabel?.font = .pretendard(.regular, size: 14)
        cell.textLabel?.textColor = .gray30
        cell.tintColor = .brightTurquoise

        if indexPath.section == 0 {
            let option = speedOptions[indexPath.row]
            cell.textLabel?.text = option.label
            cell.accessoryType = abs(option.rate - selectedSpeed) < 0.01 ? .checkmark : .none
        } else {
            let option = qualityOptions[indexPath.row]
            cell.textLabel?.text = option
            cell.accessoryType = option == selectedQuality ? .checkmark : .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let option = speedOptions[indexPath.row]
            selectedSpeed = option.rate
            onSpeedSelected?(option.rate)
        } else {
            let option = qualityOptions[indexPath.row]
            selectedQuality = option
            onQualitySelected?(option)
        }
        tableView.reloadSections([indexPath.section], with: .none)
    }
}
