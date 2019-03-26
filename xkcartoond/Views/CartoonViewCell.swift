//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Alamofire
import AlamofireImage
import EmitterKit

class CartoonViewCell: UICollectionViewCell {

   static var key: String {
      get {
         return NSStringFromClass(CartoonViewCell.self)
      }
   }

   var cartoonImage: UIImageView?
   let elevation: Int = 10
   var cartoonListener: EventListener<CartoonModel>?
   var imageListener: EventListener<UIImage>?

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

   func cartoonHandler(_ model: CartoonModel) {
      let imageEvent = Event<UIImage>()
      imageListener = imageEvent.on(imageHandler)
      ImageManager.instance.subscribe(byUrl: model.imgUrl, event: imageEvent)
   }

   func imageHandler(_ image: UIImage) {
      cartoonImage?.image = image
   }

   func setup(index: Int) {
      let cartoonEvent = Event<CartoonModel>()
      cartoonListener = cartoonEvent.on(cartoonHandler)
      CartoonManager.instance.subscribe(byIndex: index, event: cartoonEvent)
   }
}

