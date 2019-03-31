//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import EmitterKit

// TODO:
//    1. When scrolling, make sure to cancel requests that will end in showing an image outside of the screen.
//       Only focus on the requests that eventually will be presented to the user.
//       This is really visible when scrolling fast, as we then have to wait for the previous requests to finish
//          before finally managing the relevant requests that eventually will present cartoons on screen.
//    2. "Animate to center" animation for clicked cartoons.
//    3. Add progress bar or placeholder image for cartoons that do not correspond to the requested ones.
//    4. Eventually implement/design layout for showing cartoon information (like number, date and description)

class CartoonContainerVC : UICollectionViewController,
      UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {


   private var imageContainer: UIView?
   private let inset: CGFloat = 10
   private let numColumns: CGFloat = 2
   private var cartoonsListener: EventListener<Void>!

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }

   init() {
      super.init(collectionViewLayout: UICollectionViewFlowLayout())
   }

   override func viewDidLoad() {
      super.viewDidLoad()

      if let cv = collectionView {
         cv.showsVerticalScrollIndicator = false
         cv.prefetchDataSource = self
         cv.backgroundColor = .white
         cv.register(CartoonViewCell.self, forCellWithReuseIdentifier: CartoonViewCell.key)
      }

      // TODO: Make extension function to deal with safe area insets
      let sa = UIApplication.shared.delegate?.window??.safeAreaInsets
      let bottomOffset = sa?.bottom ?? 0
      let topOffset = (sa?.top ?? 0) + (navigationController?.navigationBar.bounds.height ?? 0)
      let ic = UIView()
      ic.isUserInteractionEnabled = false
      view.addSubview(ic)
      ic.snp.makeConstraints {
         m in
         m.left.width.equalToSuperview()
         m.top.equalToSuperview().offset(topOffset)
         m.bottom.equalToSuperview().offset(-bottomOffset)
      }
      imageContainer = ic

      cartoonsListener = CartoonManager.instance.currentCartoonInit.on {
         [weak self] in
         DispatchQueue.main.async {
            self?.collectionView?.reloadData()
         }
      }
   }

   private func animate(imageView: UIImageView?) {

      guard let container = imageContainer,
            let imgView = imageView,
            let img = imgView.image else {
         return
      }

      container.layoutIfNeeded()

      var animatedView = UIImageView(image: img)
      animatedView.frame = container.convert(imgView.frame, from: imgView.coordinateSpace)
      animatedView.contentMode = .scaleAspectFit

      container.addSubview(animatedView)

      animatedView.snp.makeConstraints {
         m in
         m.center.equalToSuperview()
         m.width.equalTo(imgView.bounds.width * 2)
         m.height.equalTo(imgView.bounds.height * 2)
      }

      container.setNeedsUpdateConstraints()

      UIView.animate(withDuration: 0.5, animations: {
         //animatedView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
         container.layoutIfNeeded()

      })
   }

   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                       insetForSectionAt section: Int) -> UIEdgeInsets {
      return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
   }

   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
      let sz = ((collectionView.frame.width - ((numColumns + 1) * inset)) / numColumns).rounded(.down)
      return CGSize(width: sz, height: sz)
   }

   override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return CartoonManager.instance.numCartoons ?? 0
   }

   override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CartoonViewCell.key, for: indexPath)
      if let c = cell as? CartoonViewCell {
         print("cellForItemAt(\(indexPath.row))")
         c.setup(index: indexPath.row)
      }
      return cell
   }

   func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
      print("Prefetch data for these indices: \(indexPaths)")
      for i in 0..<indexPaths.count {
         let _ = CartoonManager.instance.loadCartoon(withIndex: indexPaths[i].row)
      }
   }

   override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      if let c = collectionView.cellForItem(at: indexPath) as? CartoonViewCell {
         print("didSelectItemAt(\(indexPath.row))")
         animate(imageView: c.cartoonImage)
      }
   }
}