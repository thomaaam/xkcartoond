//
//  RootViewController.swift
//  xkcartoond
//
//  Created by Thomas Amundsen on 22/03/2019.
//  Copyright © 2019 Thomas Amundsen. All rights reserved.
//


import UIKit

class RootViewController: UINavigationController {

    var cartoonContainerVC: CartoonContainerVC!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        // Create (and navigate to) the top view controller
        cartoonContainerVC = CartoonContainerVC()
        pushViewController(cartoonContainerVC, animated: true)
    }
}

