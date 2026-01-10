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
    private let timelineSlider = UISlider()
    private let timelineHandle = UIView()
    private let timelineHandleHitArea = UIView()
    private let titleLabel = UILabel()
    private let playButton = UIButton(type: .system)

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var itemObservation: NSKeyValueObservation?
    private var timeObserverToken: Any?
    private var shouldAutoPlay = false
    private var isScrubbing = false
    private let tokenStore = TokenStore()
    private var resourceLoader: StreamingResourceLoader?
    private let controlsTapGesture = UITapGestureRecognizer()
    private var timelineHandleCenterXConstraint: Constraint?
    private let timelineHandleHitSize: CGFloat = 24

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
        updateTimelineHandlePosition()
    }

    override func configureUI() {
        titleLabel.text = "Streaming"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        playerContainer.backgroundColor = .blackTurquoise
        playerContainer.layer.cornerRadius = 0
        playerContainer.clipsToBounds = true

        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .gray15
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        playButton.layer.cornerRadius = 28
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        timelineSlider.minimumValue = 0
        timelineSlider.maximumValue = 1
        timelineSlider.value = 0
        timelineSlider.minimumTrackTintColor = .brightTurquoise
        timelineSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.2)
        timelineSlider.isUserInteractionEnabled = false
        let clearThumb = makeClearThumb(size: CGSize(width: 24, height: 24))
        timelineSlider.setThumbImage(clearThumb, for: .normal)
        timelineSlider.setThumbImage(clearThumb, for: .highlighted)
        timelineSlider.addTarget(self, action: #selector(timelineTouchDown), for: .touchDown)
        timelineSlider.addTarget(self, action: #selector(timelineValueChanged), for: .valueChanged)
        timelineSlider.addTarget(self, action: #selector(timelineTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        timelineHandle.backgroundColor = .blackTurquoise
        timelineHandle.layer.cornerRadius = 6
        timelineHandle.layer.shadowColor = UIColor.black.cgColor
        timelineHandle.layer.shadowOpacity = 0.35
        timelineHandle.layer.shadowRadius = 4
        timelineHandle.layer.shadowOffset = CGSize(width: 0, height: 1)

        timelineHandleHitArea.backgroundColor = .clear
        let handlePan = UIPanGestureRecognizer(target: self, action: #selector(handleTimelinePan(_:)))
        timelineHandleHitArea.addGestureRecognizer(handlePan)
        timelineHandleHitArea.isUserInteractionEnabled = true

        view.addSubview(playerContainer)
        playerContainer.addSubview(playButton)
        view.addSubview(timelineSlider)
        view.addSubview(timelineHandleHitArea)
        timelineHandleHitArea.addSubview(timelineHandle)

        controlsTapGesture.addTarget(self, action: #selector(handlePlayerTap))
        playerContainer.addGestureRecognizer(controlsTapGesture)
    }

    override func configureLayout() {
        playerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(playerContainer.snp.width).multipliedBy(9.0 / 16.0)
        }

        timelineSlider.snp.makeConstraints { make in
            make.top.equalTo(playerContainer.snp.bottom).offset(2)
            make.leading.trailing.equalTo(playerContainer)
            make.height.equalTo(2)
        }

        timelineHandleHitArea.snp.makeConstraints { make in
            make.centerY.equalTo(timelineSlider.snp.centerY)
            make.width.height.equalTo(timelineHandleHitSize)
            self.timelineHandleCenterXConstraint = make.centerX.equalTo(timelineSlider.snp.leading).offset(0).constraint
        }

        timelineHandle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }

        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(56)
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
        addTimeObserver(to: player)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        playerLayer?.removeFromSuperlayer()
        playerContainer.layer.insertSublayer(layer, at: 0)
        playerLayer = layer
        playerContainer.bringSubviewToFront(playButton)
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
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playButton.isHidden = false
            playButton.isUserInteractionEnabled = true
            shouldAutoPlay = false
        } else {
            if player.currentItem?.status == .readyToPlay {
                player.play()
            }
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playButton.isHidden = true
            playButton.isUserInteractionEnabled = false
        }
    }

    @objc private func handlePlayerTap() {
        guard let player else { return }
        if playButton.isHidden == false {
            playButton.isHidden = true
            playButton.isUserInteractionEnabled = false
            return
        }

        if player.timeControlStatus == .playing {
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        } else {
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
        playButton.isHidden = false
        playButton.isUserInteractionEnabled = true
    }

    @objc private func timelineTouchDown() {
        isScrubbing = true
    }

    @objc private func timelineValueChanged() {
        guard let player else { return }
        guard let duration = player.currentItem?.duration.seconds, duration.isFinite, duration > 0 else { return }
        let targetSeconds = Double(timelineSlider.value) * duration
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    @objc private func timelineTouchUp() {
        isScrubbing = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player?.pause()
        shouldAutoPlay = false
        removeTimeObserver()
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

    private func addTimeObserver(to player: AVPlayer) {
        removeTimeObserver()
        let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            guard self.isScrubbing == false else { return }
            guard let duration = player.currentItem?.duration.seconds, duration.isFinite, duration > 0 else {
                self.timelineSlider.value = 0
                self.updateTimelineHandlePosition()
                return
            }
            let current = time.seconds
            self.timelineSlider.value = Float(current / duration)
            self.updateTimelineHandlePosition()
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func makeClearThumb(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.withAlphaComponent(0.01).setFill()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.width / 2).fill()
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }

    @objc private func handleTimelinePan(_ gesture: UIPanGestureRecognizer) {
        guard let player else { return }
        let location = gesture.location(in: timelineSlider)
        let trackRect = timelineSlider.trackRect(forBounds: timelineSlider.bounds)
        let clampedX = min(max(location.x, trackRect.minX), trackRect.maxX)
        let value = valueForTimelineX(clampedX, trackRect: trackRect)
        timelineSlider.value = value
        updateTimelineHandlePosition()

        guard let duration = player.currentItem?.duration.seconds, duration.isFinite, duration > 0 else { return }
        let targetSeconds = Double(value) * duration
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)

        switch gesture.state {
        case .began:
            isScrubbing = true
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        case .changed:
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        case .ended, .cancelled, .failed:
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
            isScrubbing = false
        default:
            break
        }
    }

    private func updateTimelineHandlePosition() {
        let trackRect = timelineSlider.trackRect(forBounds: timelineSlider.bounds)
        let x = timelineX(for: timelineSlider.value, trackRect: trackRect)
        timelineHandleCenterXConstraint?.update(offset: x)
    }

    private func timelineX(for value: Float, trackRect: CGRect) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return trackRect.minX + CGFloat(clamped) * trackRect.width
    }

    private func valueForTimelineX(_ x: CGFloat, trackRect: CGRect) -> Float {
        guard trackRect.width > 0 else { return 0 }
        let clamped = min(max(x, trackRect.minX), trackRect.maxX)
        return Float((clamped - trackRect.minX) / trackRect.width)
    }
}
