//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit

// TODO

class CartoonViewCell: UICollectionViewCell {

   static var key: String {
      get {
         return NSStringFromClass(CartoonViewCell.self)
      }
   }

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }

   override init(frame: CGRect) {
      super.init(frame: frame)

      contentView.backgroundColor = .red
   }
}

