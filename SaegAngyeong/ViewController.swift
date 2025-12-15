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
        
        print(AppConfig.baseURL)
        print(AppConfig.apiKey)
        
        for family in UIFont.familyNames {
            print("🅵 \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("   - \(name)")
            }
        }
    }


}

