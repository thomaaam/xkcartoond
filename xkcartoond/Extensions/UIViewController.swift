//
// Created by Thomas Amundsen on 2019-04-02.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
   var topSafeArea: CGFloat {
      get {
         return safeAreaInsets?.top ?? 0
      }
   }
   var bottomSafeArea: CGFloat {
      get {
         return safeAreaInsets?.bottom ?? 0
      }
   }
   fileprivate var safeAreaInsets: UIEdgeInsets? {
      get {
         return UIApplication.shared.delegate?.window??.safeAreaInsets
      }
   }
}