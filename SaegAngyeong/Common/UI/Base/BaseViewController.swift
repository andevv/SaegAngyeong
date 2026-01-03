//
//  BaseViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/14/25.
//

import UIKit
import Combine

class BaseViewController<ViewModel: ViewModelType>: UIViewController {

    // MARK: - Properties
    let viewModel: ViewModel
    var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        #if DEBUG
        print("[Deinit][VC] \(type(of: self))")
        #endif
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureLayout()
        bindViewModel()
    }

    // MARK: - Template Methods (Override Points)
    func configureUI() {}
    func configureLayout() {}
    func bindViewModel() {}
}
