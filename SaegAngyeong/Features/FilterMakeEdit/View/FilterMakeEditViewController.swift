//
//  FilterMakeEditViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/29/25.
//

import UIKit

final class FilterMakeEditViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "EDIT"
        label.textColor = .gray60
        label.font = .mulgyeol(.bold, size: 18)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.titleView = titleLabel
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
