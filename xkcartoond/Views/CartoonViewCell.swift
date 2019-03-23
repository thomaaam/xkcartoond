//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Alamofire
import AlamofireImage

class CartoonViewCell: UICollectionViewCell {

   static var key: String {
      get {
         return NSStringFromClass(CartoonViewCell.self)
      }
   }

   var cartoonImage: UIImageView?

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }

   override init(frame: CGRect) {
      super.init(frame: frame)

      contentView.backgroundColor = .red

      cartoonImage = UIImageView()
      cartoonImage!.contentMode = .center

      contentView.addSubview(cartoonImage!)

      cartoonImage!.snp.makeConstraints {
         m in
         m.center.equalToSuperview()
      }
   }

   func setup(index: Int) {
      guard let cm = CartoonManager.getCartoon(fromArrayWithIndex: index),
            let imgUrl = cm.imgUrl else {
         return
      }
      let url = URL(string: imgUrl)!
      //let placeholderImage = UIImage(named: "placeholder")! // TODO

      cartoonImage?.af_setImage(withURL: url/*, placeholderImage: placeholderImage*/)
   }
}

