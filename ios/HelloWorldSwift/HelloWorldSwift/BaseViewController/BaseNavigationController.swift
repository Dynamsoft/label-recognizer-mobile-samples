//
//  BaseNavigationController.swift
//  SakuraPanoramaDemo
//
//  Created by Dynamsoft's mac on 2022/7/28.
//

import UIKit

class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {self.topViewController?.preferredStatusBarStyle ?? .lightContent}
    }

}
