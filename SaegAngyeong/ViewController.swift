//
//  ViewController.swift
//  SaegAngyeong
//
//  Created by andev on 12/10/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkGray
        
        AppLogger.debug("baseURL: \(AppConfig.baseURL)")
        AppLogger.debug("apiKey: \(AppConfig.apiKey)")
        
        for family in UIFont.familyNames {
            AppLogger.debug("🅵 \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                AppLogger.debug("   - \(name)")
            }
        }
    }


}
