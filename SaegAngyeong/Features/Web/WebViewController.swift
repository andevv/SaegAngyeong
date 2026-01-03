//
//  WebViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/17/25.
//

import UIKit
import WebKit
import SnapKit

final class WebViewController: UIViewController, WKScriptMessageHandler {

    private let url: URL
    private let sesacKey: String
    private let accessTokenProvider: () -> String?
    private var webView: WKWebView!

    init(url: URL, sesacKey: String, accessTokenProvider: @escaping () -> String?) {
        self.url = url
        self.sesacKey = sesacKey
        self.accessTokenProvider = accessTokenProvider
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        #if DEBUG
        print("[Deinit][VC] \(type(of: self))")
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureWebView()
        configureCloseButton()
        load()
    }

    private func configureCloseButton() {
        let button = UIButton(type: .system)
        button.setTitle("닫기", for: .normal)
        button.setTitleColor(.gray60, for: .normal)
        button.titleLabel?.font = .pretendard(.medium, size: 14)
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        button.backgroundColor = UIColor.gray45.withAlphaComponent(0.2)
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        view.addSubview(button)
        view.bringSubviewToFront(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.equalToSuperview().offset(24)
        }
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    private func configureWebView() {
        let controller = WKUserContentController()
        controller.add(self, name: "click_attendance_button")
        controller.add(self, name: "complete_attendance")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func load() {
        var request = URLRequest(url: url)
        request.setValue(sesacKey, forHTTPHeaderField: "SeSACKey")
        if let token = accessTokenProvider(), !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "Authorization")
        }
        webView.load(request)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "click_attendance_button":
            sendAccessTokenToWeb()
        case "complete_attendance":
            handleAttendanceCompletion(count: message.body)
        default:
            break
        }
    }

    private func sendAccessTokenToWeb() {
        guard let token = accessTokenProvider(), !token.isEmpty else { return }
        let js = "requestAttendance('\(token)')"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func handleAttendanceCompletion(count: Any) {
        let countText: String
        if let number = count as? Int {
            countText = "\(number)"
        } else if let str = count as? String {
            countText = str
        } else {
            countText = ""
        }
        let alert = UIAlertController(
            title: "출석 완료",
            message: countText.isEmpty ? "출석이 완료되었습니다." : "\(countText)번째 출석 완료!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError(error)
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "웹뷰 오류", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "닫기", style: .default))
        present(alert, animated: true)
    }
}
