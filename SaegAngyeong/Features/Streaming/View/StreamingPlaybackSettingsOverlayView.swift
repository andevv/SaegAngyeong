//
//  StreamingPlaybackSettingsOverlayView.swift
//  SaegAngyeong
//
//  Created by andev on 1/18/26.
//

import UIKit
import SnapKit

final class StreamingPlaybackSettingsOverlayView: UIView {
    struct SpeedOption {
        let label: String
        let rate: Float
    }

    private let speedOptions: [SpeedOption]
    private var selectedSpeed: Float
    private let qualityOptions: [String]
    private var selectedQuality: String
    private let horizontalInset: CGFloat

    private let dimView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)

    var onSpeedSelected: ((Float) -> Void)?
    var onQualitySelected: ((String) -> Void)?
    var onDismiss: (() -> Void)?

    init(
        speedOptions: [SpeedOption],
        selectedSpeed: Float,
        qualityOptions: [String],
        selectedQuality: String,
        horizontalInset: CGFloat = 16
    ) {
        self.speedOptions = speedOptions
        self.selectedSpeed = selectedSpeed
        self.qualityOptions = qualityOptions
        self.selectedQuality = selectedQuality
        self.horizontalInset = horizontalInset
        super.init(frame: .zero)
        configureUI()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func configureUI() {
        backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        dimView.alpha = 0
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(didTapDim))
        dimView.addGestureRecognizer(dismissTap)

        containerView.backgroundColor = .blackTurquoise
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous
        containerView.clipsToBounds = true

        titleLabel.text = "재생 설정"
        titleLabel.font = .pretendard(.medium, size: 14)
        titleLabel.textColor = .gray60
        titleLabel.textAlignment = .center

        tableView.backgroundColor = .blackTurquoise
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.06)
        tableView.rowHeight = 48
        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = true
        tableView.alwaysBounceVertical = false
        tableView.alwaysBounceHorizontal = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaybackSettingsCell")

        addSubview(dimView)
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(tableView)
    }

    private func configureLayout() {
        dimView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(320)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func present(animated: Bool) {
        if animated {
            containerView.transform = CGAffineTransform(translationX: 0, y: 40)
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
                self.dimView.alpha = 1
                self.containerView.transform = .identity
            }
        } else {
            dimView.alpha = 1
            containerView.transform = .identity
        }
    }

    func dismiss(animated: Bool) {
        let animations = {
            self.dimView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 40)
        }
        let completion: (Bool) -> Void = { _ in
            self.onDismiss?()
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

    @objc private func didTapDim() {
        dismiss(animated: true)
    }
}

extension StreamingPlaybackSettingsOverlayView: UITableViewDataSource, UITableViewDelegate {
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
        let selectedBackground = UIView()
        selectedBackground.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        cell.selectedBackgroundView = selectedBackground
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
