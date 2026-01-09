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
    private var itemObservation: NSKeyValueObservation?
    private var shouldAutoPlay = false
    private let tokenStore = TokenStore()
    private var resourceLoader: StreamingResourceLoader?

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
        #if DEBUG
        print("[Streaming] stream URL: \(url.absoluteString)")
        #endif
        let assetOptions: [String: Any] = [
            AVURLAssetAllowsCellularAccessKey: true
        ]
        let headersProvider: () -> [String: String] = { [weak self] in
            guard let self else { return [:] }
            var headers: [String: String] = [
                "SeSACKey": AppConfig.apiKey
            ]
            if let accessToken = self.tokenStore.accessToken {
                headers["Authorization"] = accessToken
            }
            return headers
        }
        let loader = StreamingResourceLoader(
            originalScheme: url.scheme ?? "http",
            disableSubtitles: true,
            headersProvider: headersProvider
        )
        self.resourceLoader = loader
        let assetURL = StreamingResourceLoader.makeCustomSchemeURL(from: url) ?? url
        let asset = AVURLAsset(url: assetURL, options: assetOptions)
        asset.resourceLoader.setDelegate(loader, queue: DispatchQueue(label: "streaming.resource.loader"))
        let item = AVPlayerItem(asset: asset)
        itemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                #if DEBUG
                print("[Streaming] item ready")
                #endif
                if self.shouldAutoPlay {
                    self.player?.play()
                }
            case .failed:
                #if DEBUG
                if let error = item.error as NSError? {
                    print("[Streaming] player item failed: \(error.domain) \(error.code) \(error.localizedDescription)")
                } else {
                    print("[Streaming] player item failed: unknown")
                }
                #endif
            default:
                break
            }
        }
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.new], context: nil)
        let player = AVPlayer(playerItem: item)
        self.player = player
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        playerContainer.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        playerContainer.layer.addSublayer(layer)
        playerLayer = layer
    }

    @objc private func playTapped() {
        guard let player else { return }
        shouldAutoPlay = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("[Streaming] audio session error: \(error)")
            #endif
        }
        if player.timeControlStatus == .playing {
            player.pause()
            playButton.setTitle("재생", for: .normal)
            shouldAutoPlay = false
        } else {
            if player.currentItem?.status == .readyToPlay {
                player.play()
            }
            playButton.setTitle("일시정지", for: .normal)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
        shouldAutoPlay = false
        if let item = player?.currentItem {
            item.removeObserver(self, forKeyPath: "loadedTimeRanges")
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "loadedTimeRanges",
              let item = object as? AVPlayerItem,
              let range = item.loadedTimeRanges.first?.timeRangeValue else { return }
        #if DEBUG
        let start = CMTimeGetSeconds(range.start)
        let duration = CMTimeGetSeconds(range.duration)
        print("[Streaming] buffered: \(start) + \(duration)")
        #endif
    }
}
