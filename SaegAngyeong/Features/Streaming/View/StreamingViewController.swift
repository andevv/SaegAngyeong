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
    private let infoContainer = UIView()
    private let infoTitleLabel = UILabel()
    private let infoSubtitleLabel = UILabel()
    private let infoMetaLabel = UILabel()
    private let liveBadge = UILabel()
    private let playButton = UIButton(type: .system)
    private let fullScreenButton = UIButton(type: .system)
    private let miniPlayButton = UIButton(type: .system)
    private let miniCloseButton = UIButton(type: .system)
    private let bufferingIndicator = UIActivityIndicatorView(style: .medium)

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let playbackService: StreamingPlaybackService
    private let videoID: String
    private let viewCountText: String
    private let likeCountText: String
    private var playerLayer: AVPlayerLayer?
    private var itemObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var timeObserverToken: Any?
    private var shouldAutoPlay = false
    private var isScrubbing = false
    private var isMiniPlayer = false
    private var isFullscreen = false
    private var isControlsVisible = false
    private let tokenStore = TokenStore()
    private let controlsTapGesture = UITapGestureRecognizer()
    private var timelineHandleCenterXConstraint: Constraint?
    private let timelineHandleHitSize: CGFloat = 24
    private var playerTopConstraint: Constraint?
    private var playerLeadingConstraint: Constraint?
    private var playerWidthConstraint: Constraint?
    private var playerHeightConstraint: Constraint?
    private var sliderHeightConstraint: Constraint?
    var onCloseRequested: (() -> Void)?
    var onMiniPlayerRequested: (() -> Void)?

    private var player: AVPlayer {
        playbackService.player
    }

    init(
        viewModel: StreamingViewModel,
        videoID: String,
        playbackService: StreamingPlaybackService,
        viewCountText: String,
        likeCountText: String
    ) {
        self.videoID = videoID
        self.playbackService = playbackService
        self.viewCountText = viewCountText
        self.likeCountText = likeCountText
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
        updatePlayerLayout(animated: false)
        playerContainer.bringSubviewToFront(playButton)
        playerContainer.bringSubviewToFront(fullScreenButton)
        playerContainer.bringSubviewToFront(miniPlayButton)
        playerContainer.bringSubviewToFront(miniCloseButton)
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

        fullScreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        fullScreenButton.tintColor = .gray15
        fullScreenButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        fullScreenButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        fullScreenButton.layer.cornerRadius = 14
        fullScreenButton.addTarget(self, action: #selector(fullScreenTapped), for: .touchUpInside)

        miniPlayButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        miniPlayButton.tintColor = .gray15
        miniPlayButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        miniPlayButton.layer.cornerRadius = 14
        miniPlayButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        miniPlayButton.isHidden = true

        miniCloseButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        miniCloseButton.tintColor = .gray15
        miniCloseButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        miniCloseButton.layer.cornerRadius = 14
        miniCloseButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        miniCloseButton.isHidden = true

        bufferingIndicator.hidesWhenStopped = true
        bufferingIndicator.color = .gray15
        bufferingIndicator.isHidden = true

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

        infoContainer.backgroundColor = .black

        infoTitleLabel.textColor = .gray30
        infoTitleLabel.font = .pretendard(.medium, size: 16)
        infoTitleLabel.numberOfLines = 2

        infoSubtitleLabel.textColor = .gray60
        infoSubtitleLabel.font = .pretendard(.regular, size: 12)
        infoSubtitleLabel.numberOfLines = 1

        infoMetaLabel.textColor = .gray60
        infoMetaLabel.font = .pretendard(.regular, size: 11)
        infoMetaLabel.numberOfLines = 1

        liveBadge.text = "LIVE"
        liveBadge.textColor = .gray30
        liveBadge.font = .pretendard(.medium, size: 10)
        liveBadge.textAlignment = .center
        liveBadge.backgroundColor = .brightTurquoise
        liveBadge.layer.cornerRadius = 8
        liveBadge.clipsToBounds = true

        view.addSubview(playerContainer)
        playerContainer.addSubview(playButton)
        playerContainer.addSubview(fullScreenButton)
        playerContainer.addSubview(miniPlayButton)
        playerContainer.addSubview(miniCloseButton)
        playerContainer.addSubview(bufferingIndicator)
        view.addSubview(timelineSlider)
        view.addSubview(timelineHandleHitArea)
        view.addSubview(infoContainer)
        infoContainer.addSubview(infoTitleLabel)
        infoContainer.addSubview(infoSubtitleLabel)
        infoContainer.addSubview(infoMetaLabel)
        infoContainer.addSubview(liveBadge)
        timelineHandleHitArea.addSubview(timelineHandle)

        controlsTapGesture.addTarget(self, action: #selector(handlePlayerTap))
        controlsTapGesture.cancelsTouchesInView = false
        controlsTapGesture.delegate = self
        playerContainer.addGestureRecognizer(controlsTapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePlayerPan(_:)))
        playerContainer.addGestureRecognizer(panGesture)
    }

    override func configureLayout() {
        playerContainer.snp.makeConstraints { make in
            playerTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide).constraint
            playerLeadingConstraint = make.leading.equalToSuperview().constraint
            playerWidthConstraint = make.width.equalTo(0).constraint
            playerHeightConstraint = make.height.equalTo(0).constraint
        }

        timelineSlider.snp.makeConstraints { make in
            make.top.equalTo(playerContainer.snp.bottom).offset(2)
            make.leading.trailing.equalTo(playerContainer)
            sliderHeightConstraint = make.height.equalTo(2).constraint
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

        infoContainer.snp.makeConstraints { make in
            make.top.equalTo(timelineSlider.snp.bottom).offset(14)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
        }

        liveBadge.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(16)
        }

        infoTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalTo(liveBadge.snp.trailing).offset(8)
            make.trailing.equalToSuperview()
        }

        infoSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(infoTitleLabel.snp.bottom).offset(6)
            make.leading.equalTo(infoTitleLabel)
            make.trailing.equalTo(infoTitleLabel)
        }

        infoMetaLabel.snp.makeConstraints { make in
            make.top.equalTo(infoSubtitleLabel.snp.bottom).offset(6)
            make.leading.equalTo(infoTitleLabel)
            make.trailing.equalTo(infoTitleLabel)
            make.bottom.equalToSuperview()
        }

        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(56)
        }

        fullScreenButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
            make.width.height.equalTo(28)
        }

        miniPlayButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.width.height.equalTo(28)
        }

        miniCloseButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.width.height.equalTo(28)
        }

        bufferingIndicator.snp.makeConstraints { make in
            make.center.equalTo(playButton)
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

        infoTitleLabel.text = playbackService.currentTitle ?? "Streaming"
        infoSubtitleLabel.text = "실시간 스트리밍 중"
        infoMetaLabel.text = "\(viewCountText) · \(likeCountText)"
    }

    private func setupPlayer(url: URL) {
        #if DEBUG
        print("[Streaming] stream URL: \(url.absoluteString)")
        #endif
        isControlsVisible = true
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
        let item = playbackService.prepare(
            videoID: videoID,
            url: url,
            headersProvider: headersProvider
        )
        itemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                #if DEBUG
                print("[Streaming] item ready")
                #endif
                if self.shouldAutoPlay {
                    self.player.play()
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
        timeControlObservation?.invalidate()
        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            guard let self else { return }
            switch player.timeControlStatus {
            case .waitingToPlayAtSpecifiedRate:
                self.showBufferingIndicator(true)
            case .playing, .paused:
                self.showBufferingIndicator(false)
            @unknown default:
                self.showBufferingIndicator(false)
            }
            self.updatePlayIcons()
        }
        addTimeObserver(to: player)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        playerLayer?.removeFromSuperlayer()
        playerContainer.layer.insertSublayer(layer, at: 0)
        playerLayer = layer
        playerContainer.bringSubviewToFront(playButton)
        playerContainer.bringSubviewToFront(fullScreenButton)
        playerContainer.bringSubviewToFront(miniPlayButton)
        playerContainer.bringSubviewToFront(miniCloseButton)
    }

    @objc private func playTapped() {
        let player = player
        guard player.currentItem != nil else { return }
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
            shouldAutoPlay = false
        } else {
            if player.currentItem?.status == .readyToPlay {
                player.play()
            }
        }
        updatePlayIcons()
    }

    @objc private func closeTapped() {
        playbackService.stop()
        shouldAutoPlay = false
        onCloseRequested?()
    }

    @objc private func fullScreenTapped() {
        if isMiniPlayer {
            setMiniPlayer(false, animated: true)
        }
        isFullscreen.toggle()
        updateFullscreenIcon()
        updatePlayerLayout(animated: true)
        setNeedsUpdateOfSupportedInterfaceOrientations()
        let orientation: UIInterfaceOrientation = isFullscreen ? .landscapeRight : .portrait
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }

    @objc private func handlePlayerTap() {
        guard player.currentItem != nil else { return }
        if isMiniPlayer {
            setMiniPlayer(false, animated: true)
            return
        }
        isControlsVisible.toggle()
        updatePlayIcons()
    }

    @objc private func handlePlayerPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        if gesture.state == .ended || gesture.state == .cancelled {
            if isMiniPlayer {
                if translation.y < -120 || velocity.y < -600 {
                    setMiniPlayer(false, animated: true)
                }
            } else {
                if translation.y > 120 || velocity.y > 600 {
                    setMiniPlayer(true, animated: true)
                }
            }
        }
    }

    private func setMiniPlayer(_ mini: Bool, animated: Bool) {
        if mini {
            onMiniPlayerRequested?()
            return
        }
        guard isMiniPlayer != mini else { return }
        isMiniPlayer = mini
        if mini {
            isControlsVisible = false
        }
        updatePlayerLayout(animated: animated)
    }

    private func updatePlayerLayout(animated: Bool) {
        let updates = { [weak self] in
            guard let self else { return }
            if self.isFullscreen {
                self.playerWidthConstraint?.update(offset: self.view.bounds.width)
                self.playerHeightConstraint?.update(offset: self.view.bounds.height)
                self.playerLeadingConstraint?.update(offset: 0)
                self.playerTopConstraint?.update(offset: 0)
                self.playerContainer.layer.cornerRadius = 0
                self.playerContainer.clipsToBounds = true
                self.sliderHeightConstraint?.update(offset: 0)
                self.timelineSlider.alpha = 0
                self.timelineHandleHitArea.alpha = 0
                self.infoContainer.alpha = 0
                self.fullScreenButton.isHidden = false
                self.miniPlayButton.isHidden = true
                self.miniCloseButton.isHidden = true
                self.view.backgroundColor = .black
                self.navigationController?.setNavigationBarHidden(true, animated: animated)
            } else if self.isMiniPlayer {
                let width: CGFloat = 160
                let height: CGFloat = width * 9.0 / 16.0
                let safeRight = self.view.safeAreaInsets.right
                let safeBottom = self.view.safeAreaInsets.bottom
                let safeTop = self.view.safeAreaInsets.top
                self.playerWidthConstraint?.update(offset: width)
                self.playerHeightConstraint?.update(offset: height)
                let leading = self.view.bounds.width - safeRight - width - 16
                self.playerLeadingConstraint?.update(offset: max(16, leading))
                let top = self.view.bounds.height - safeBottom - height - 16
                self.playerTopConstraint?.update(offset: max(0, top - safeTop))
                self.playerContainer.layer.cornerRadius = 12
                self.playerContainer.clipsToBounds = true
                self.sliderHeightConstraint?.update(offset: 0)
                self.timelineSlider.alpha = 0
                self.timelineHandleHitArea.alpha = 0
                self.infoContainer.alpha = 0
                self.miniPlayButton.isHidden = false
                self.miniCloseButton.isHidden = false
                self.fullScreenButton.isHidden = true
                self.view.backgroundColor = .clear
                self.navigationController?.setNavigationBarHidden(true, animated: animated)
            } else {
                let width = self.view.bounds.width
                self.playerWidthConstraint?.update(offset: width)
                self.playerHeightConstraint?.update(offset: width * 9.0 / 16.0)
                self.playerLeadingConstraint?.update(offset: 0)
                self.playerTopConstraint?.update(offset: 0)
                self.playerContainer.layer.cornerRadius = 0
                self.playerContainer.clipsToBounds = true
                self.sliderHeightConstraint?.update(offset: 2)
                self.timelineSlider.alpha = 1
                self.timelineHandleHitArea.alpha = 1
                self.infoContainer.alpha = 1
                self.miniPlayButton.isHidden = true
                self.miniCloseButton.isHidden = true
                self.fullScreenButton.isHidden = false
                self.view.backgroundColor = .black
                self.navigationController?.setNavigationBarHidden(false, animated: animated)
            }
            self.updatePlayIcons()
            self.updateFullscreenIcon()
            self.view.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
                updates()
            }
        } else {
            updates()
        }
    }

    @objc private func timelineTouchDown() {
        isScrubbing = true
    }

    @objc private func timelineValueChanged() {
        let player = player
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
        removeTimeObserver()
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        if let item = player.currentItem {
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
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func showBufferingIndicator(_ show: Bool) {
        if show {
            bufferingIndicator.startAnimating()
            bufferingIndicator.isHidden = false
        } else {
            bufferingIndicator.stopAnimating()
            bufferingIndicator.isHidden = true
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
        let player = player
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

    private func updatePlayIcons() {
        let player = player
        let imageName = player.timeControlStatus == .playing ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: imageName)
        playButton.setImage(image, for: .normal)
        miniPlayButton.setImage(image, for: .normal)

        if isMiniPlayer {
            playButton.isHidden = true
            playButton.isUserInteractionEnabled = false
            fullScreenButton.isHidden = true
            fullScreenButton.isUserInteractionEnabled = false
            return
        }
        playButton.isHidden = !isControlsVisible
        playButton.isUserInteractionEnabled = isControlsVisible
        fullScreenButton.isHidden = !isControlsVisible
        fullScreenButton.isUserInteractionEnabled = isControlsVisible
    }

    private func updateFullscreenIcon() {
        let imageName = isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
        fullScreenButton.setImage(UIImage(systemName: imageName), for: .normal)
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        isFullscreen ? .landscape : .portrait
    }
}

extension StreamingViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchedView = touch.view
        if touchedView is UIControl { return false }
        if touchedView?.isDescendant(of: playButton) == true { return false }
        if touchedView?.isDescendant(of: fullScreenButton) == true { return false }
        if touchedView?.isDescendant(of: miniPlayButton) == true { return false }
        if touchedView?.isDescendant(of: miniCloseButton) == true { return false }
        if touchedView?.isDescendant(of: timelineHandleHitArea) == true { return false }
        return true
    }
}
