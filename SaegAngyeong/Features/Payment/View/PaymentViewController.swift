//
//  PaymentViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/31/25.
//

import UIKit
import Combine
import SnapKit
import iamport_ios

final class PaymentViewController: BaseViewController<PaymentViewModel> {

    var onPaymentSuccess: (() -> Void)?

    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let validateSubject = PassthroughSubject<String, Never>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        viewDidLoadSubject.send(())
    }

    override func configureUI() {
        statusLabel.text = "결제를 진행 중입니다..."
        statusLabel.font = .pretendard(.medium, size: 14)
        statusLabel.textColor = .gray60
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        activityIndicator.color = .gray60
        activityIndicator.startAnimating()

        view.addSubview(statusLabel)
        view.addSubview(activityIndicator)
    }

    override func configureLayout() {
        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(statusLabel.snp.top).offset(-16)
        }
    }

    override func bindViewModel() {
        let input = PaymentViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            validatePayment: validateSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.orderInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.startPayment(orderInfo: info)
            }
            .store(in: &cancellables)

        output.paymentValidated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.presentSuccessAlert()
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func startPayment(orderInfo: PaymentOrderInfo) {
        guard let userCode = AppConfig.iamportUserCode, !userCode.isEmpty else {
            presentMessage("포트원 설정이 필요합니다. IAMPORT_USER_CODE를 확인해주세요.")
            return
        }
        guard let appScheme = appScheme() else {
            presentMessage("앱 스킴 설정이 필요합니다. Info.plist의 URL Scheme를 확인해주세요.")
            return
        }

        let pgName = AppConfig.iamportPG ?? "html5_inicis"
        let payment = IamportPayment(pg: pgName, merchant_uid: orderInfo.orderCode, amount: "\(orderInfo.amount)")
        payment.name = orderInfo.title
        payment.app_scheme = appScheme

        Iamport.shared.payment(viewController: self, userCode: userCode, payment: payment) { [weak self] response in
            guard let self else { return }
            guard let response else {
                self.presentMessage("결제가 취소되었습니다.")
                return
            }
            if response.success == true, let impUID = response.imp_uid {
                self.validateSubject.send(impUID)
            } else {
                self.presentMessage(response.error_msg ?? "결제에 실패했습니다.")
            }
        }
    }

    private func appScheme() -> String? {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return nil
        }
        let schemes = urlTypes
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }
            .flatMap { $0 }
        return schemes.first
    }

    private func presentSuccessAlert() {
        let alert = UIAlertController(title: "결제 완료", message: "결제가 정상적으로 완료되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
            self?.onPaymentSuccess?()
            self?.close()
        }))
        present(alert, animated: true)
    }

    private func presentError(_ error: Error) {
        presentMessage(error.localizedDescription)
    }

    private func presentMessage(_ message: String) {
        let alert = UIAlertController(title: "안내", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { [weak self] _ in
            self?.close()
        }))
        present(alert, animated: true)
    }

    private func close() {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
