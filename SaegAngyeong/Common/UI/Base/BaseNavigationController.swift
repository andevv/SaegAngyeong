//
//  BaseNavigationController.swift
//  SaegAngyeong
//
//  Created by andev on 12/22/25.
//

import UIKit

final class BaseNavigationController: UINavigationController {
    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
}
