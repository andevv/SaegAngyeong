//
//  StreamingViewController.swift
//  SaegAngyeong
//
//  Created by andev on 1/9/26.
//

import UIKit
import Combine
import AVFoundation
import SnapKit

final class StreamingViewController: BaseViewController<StreamingViewModel> {
    private let playerContainer = UIView()
    private let titleLabel = UILabel()
    private let playButton = UIButton(type: .system)

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override init(viewModel: StreamingViewModel) {
        super.init(viewModel: viewModel)
        hidesBottomBarWhenPushed = true
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = playerContainer.bounds
    }

    override func configureUI() {
        titleLabel.text = "Streaming"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        playerContainer.backgroundColor = .blackTurquoise
        playerContainer.layer.cornerRadius = 16
        playerContainer.clipsToBounds = true

        playButton.setTitle("재생", for: .normal)
        playButton.titleLabel?.font = .pretendard(.medium, size: 14)
        playButton.setTitleColor(.gray30, for: .normal)
        playButton.backgroundColor = .brightTurquoise.withAlphaComponent(0.2)
        playButton.layer.cornerRadius = 12
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        view.addSubview(playerContainer)
        view.addSubview(playButton)
    }

    override func configureLayout() {
        playerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(playerContainer.snp.width).multipliedBy(9.0 / 16.0)
        }

        playButton.snp.makeConstraints { make in
            make.top.equalTo(playerContainer.snp.bottom).offset(16)
            make.leading.trailing.equalTo(playerContainer)
            make.height.equalTo(44)
        }
    }

    override func bindViewModel() {
        let input = StreamingViewModel.Input(viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher())
        let output = viewModel.transform(input: input)

        output.streamURL
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.setupPlayer(url: url)
            }
            .store(in: &cancellables)
    }

    private func setupPlayer(url: URL) {
        let player = AVPlayer(url: url)
        self.player = player
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        playerContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        playerContainer.layer.addSublayer(layer)
        playerLayer = layer
    }

    @objc private func playTapped() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            playButton.setTitle("재생", for: .normal)
        } else {
            player.play()
            playButton.setTitle("일시정지", for: .normal)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
    }
}
