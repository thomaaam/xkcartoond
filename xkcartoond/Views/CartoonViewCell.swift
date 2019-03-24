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
   let elevation: Int = 10

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }

   override init(frame: CGRect) {
      super.init(frame: frame)

      cartoonImage = UIImageView()
      cartoonImage!.contentMode = .scaleAspectFit

      // Apply some elevation
      if let layer = cartoonImage?.layer {
         layer.masksToBounds = false
         layer.shadowColor = UIColor.black.cgColor
         layer.shadowOffset = CGSize(width: 0, height: elevation)
         layer.shadowRadius = CGFloat(elevation)
         layer.shadowOpacity = 0.25
      }

      contentView.addSubview(cartoonImage!)

      cartoonImage!.snp.makeConstraints {
         m in
         m.center.equalToSuperview()
         m.width.equalToSuperview()
         m.height.equalToSuperview()
      }
   }

   func setup(index: Int) {
      guard let cm = CartoonManager.getCartoon(fromDictByIndex: index),
            let imgUrl = cm.imgUrl,
            let number = cm.number else {
         print("setup(\(index))", "Cartoon not ready")
         // TODO: Set placeholder image somehow
         return
      }
      let url = URL(string: imgUrl)!
      //let placeholderImage = UIImage(named: "placeholder")! // TODO

      print("setup(\(index))", "Set image \(url) \(String(describing: cartoonImage))")

      cartoonImage?.af_setImage(withURL: url/*, placeholderImage: placeholderImage*/) {
         [weak self] response in
         // TODO: Manage caching
         /*
         switch(response.result) {
         case .success(let image):
            StorageManager.instance.storeCartoonImage(byNumber: number, image: image)
         case .failure(let error):
            if let cached = StorageManager.instance.getCartoonImage(byNumber: number) {
               self?.cartoonImage?.image = cached
            }
         }
         */
      }
   }
}

