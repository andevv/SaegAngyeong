//
//  MiniPlayerView.swift
//  SaegAngyeong
//
//  Created by andev on 1/14/26.
//

import UIKit
import SnapKit
import AVFoundation

final class MiniPlayerView: UIView, UIGestureRecognizerDelegate {
    private let playerContainer = UIView()
    private let titleLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private var playerLayer: AVPlayerLayer?
    private var timeControlObservation: NSKeyValueObservation?
    private var playbackService: StreamingPlaybackService?

    var onExpand: (() -> Void)?
    var onClose: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .blackTurquoise
        layer.cornerRadius = 14
        clipsToBounds = true

        playerContainer.backgroundColor = .blackTurquoise
        playerContainer.clipsToBounds = true
        playerContainer.layer.cornerRadius = 10

        titleLabel.text = "Streaming"
        titleLabel.font = .pretendard(.medium, size: 13)
        titleLabel.textColor = .gray30
        titleLabel.numberOfLines = 1

        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .gray30
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .gray60
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        addSubview(playerContainer)
        addSubview(titleLabel)
        addSubview(playButton)
        addSubview(closeButton)

        playerContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(84)
            make.height.equalTo(84 * 9.0 / 16.0)
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        playButton.snp.makeConstraints { make in
            make.trailing.equalTo(closeButton.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(playerContainer.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(playButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleExpand))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = playerContainer.bounds
    }

    func bind(service: StreamingPlaybackService) {
        playbackService = service
        titleLabel.text = service.currentTitle ?? "Streaming"
        service.onTitleChanged = { [weak self] title in
            self?.titleLabel.text = title ?? "Streaming"
        }
        let layer = AVPlayerLayer(player: service.player)
        layer.videoGravity = .resizeAspect
        playerLayer?.removeFromSuperlayer()
        playerContainer.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        timeControlObservation?.invalidate()
        timeControlObservation = service.player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            self?.updatePlayIcon(isPlaying: player.timeControlStatus == .playing)
        }
    }

    private func updatePlayIcon(isPlaying: Bool) {
        let name = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: name), for: .normal)
    }

    @objc private func playTapped() {
        guard let service = playbackService else { return }
        if service.player.timeControlStatus == .playing {
            service.player.pause()
        } else {
            service.player.play()
        }
    }

    @objc private func closeTapped() {
        onClose?()
    }

    @objc private func handleExpand() {
        onExpand?()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIControl { return false }
        return true
    }

    deinit {
        timeControlObservation?.invalidate()
        playbackService?.onTitleChanged = nil
    }
}
