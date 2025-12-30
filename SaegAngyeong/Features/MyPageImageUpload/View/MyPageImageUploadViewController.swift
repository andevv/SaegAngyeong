//
//  MyPageImageUploadViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/30/25.
//

import UIKit
import SnapKit
import Combine
import PhotosUI

final class MyPageImageUploadViewController: BaseViewController<MyPageImageUploadViewModel> {
    private let previewContainer = UIView()
    private let previewImageView = UIImageView()
    private let selectButton = UIButton(type: .system)
    private let uploadButton = UIButton(type: .system)

    private let imageSelectedSubject = PassthroughSubject<UIImage?, Never>()
    private let uploadTappedSubject = PassthroughSubject<Void, Never>()

    var onUploadCompleted: ((URL) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.gray60
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray60
        navigationController?.navigationBar.barStyle = .black
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func configureUI() {
        let titleLabel = UILabel()
        titleLabel.text = "프로필 이미지 변경"
        titleLabel.textColor = .gray60
        titleLabel.font = .mulgyeol(.bold, size: 18)
        navigationItem.titleView = titleLabel

        previewContainer.backgroundColor = .blackTurquoise
        previewContainer.layer.cornerRadius = 16
        previewContainer.layer.borderWidth = 1
        previewContainer.layer.borderColor = UIColor.gray90.withAlphaComponent(0.3).cgColor

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.layer.cornerRadius = 16

        selectButton.setTitle("사진 선택", for: .normal)
        selectButton.titleLabel?.font = .pretendard(.medium, size: 12)
        selectButton.setTitleColor(.gray60, for: .normal)
        selectButton.layer.borderWidth = 1
        selectButton.layer.borderColor = UIColor.gray90.withAlphaComponent(0.4).cgColor
        selectButton.layer.cornerRadius = 12
        selectButton.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)

        uploadButton.setTitle("업로드", for: .normal)
        uploadButton.titleLabel?.font = .pretendard(.bold, size: 14)
        uploadButton.setTitleColor(.gray30, for: .normal)
        uploadButton.backgroundColor = .brightTurquoise.withAlphaComponent(0.8)
        uploadButton.layer.cornerRadius = 12
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)

        view.addSubview(previewContainer)
        previewContainer.addSubview(previewImageView)
        view.addSubview(selectButton)
        view.addSubview(uploadButton)
    }

    override func configureLayout() {
        previewContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(previewContainer.snp.width)
        }

        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        selectButton.snp.makeConstraints { make in
            make.top.equalTo(previewContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

        uploadButton.snp.makeConstraints { make in
            make.top.equalTo(selectButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(46)
        }
    }

    override func bindViewModel() {
        let input = MyPageImageUploadViewModel.Input(
            imageSelected: imageSelectedSubject.eraseToAnyPublisher(),
            uploadTapped: uploadTappedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.previewImage
            .sink { [weak self] image in
                self?.previewImageView.image = image
            }
            .store(in: &cancellables)

        output.isUploading
            .sink { [weak self] uploading in
                self?.uploadButton.isEnabled = !uploading
                self?.uploadButton.alpha = uploading ? 0.6 : 1.0
            }
            .store(in: &cancellables)

        output.uploadCompleted
            .sink { [weak self] url in
                self?.onUploadCompleted?(url)
                self?.presentSuccess()
            }
            .store(in: &cancellables)

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.presentError(error)
            }
            .store(in: &cancellables)
    }

    private func presentSuccess() {
        let alert = UIAlertController(title: "완료", message: "프로필 이미지가 변경되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func presentError(_ error: Error) {
        let message: String
        if let domainError = error as? DomainError {
            switch domainError {
            case .validation(let text):
                message = text
            case .unknown(let text):
                message = text ?? "요청 처리 중 오류가 발생했습니다."
            default:
                message = "요청 처리 중 오류가 발생했습니다."
            }
        } else {
            message = error.localizedDescription
        }
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func selectTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func uploadTapped() {
        uploadTappedSubject.send(())
    }
}

extension MyPageImageUploadViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.imageSelectedSubject.send(image)
            }
        }
    }
}
