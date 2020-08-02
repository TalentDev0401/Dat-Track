//
//  UINavigationController.swift
//  Audio
//
//  Created by Talent on 02.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

// MARK: Pop up into specific view controller in UInavigationController
extension UINavigationController {
  func popToViewController(ofClass: AnyClass, animated: Bool = true) {
    if let vc = viewControllers.last(where: { $0.isKind(of: ofClass) }) {
      popToViewController(vc, animated: animated)
    }
  }
}
