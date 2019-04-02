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
//    (√) 2. "Animate to center" animation for clicked cartoons.
//    3. Add progress bar or placeholder image for cartoons that do not correspond to the requested ones.
//    4. Eventually implement/design layout for showing cartoon information (like number, date and description)

class CartoonContainerVC : UICollectionViewController,
      UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {


   private var imageContainer: UIView?
   private let inset: CGFloat = 10
   private let numColumns: CGFloat = 2
   private var cartoonsListener: EventListener<Void>!
   private var animatedImageView: UIImageView?

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
      let topOffset = (sa?.top ?? 0) + (navigationController?.navigationBar.bounds.height ?? 0)
      let ic = UIView()
      ic.isUserInteractionEnabled = false
      view.addSubview(ic)
      ic.snp.makeConstraints {
         m in
         m.left.width.equalToSuperview()
         m.top.equalToSuperview().offset(topOffset)
         m.bottom.equalToSuperview()
      }
      imageContainer = ic

      cartoonsListener = CartoonManager.instance.currentCartoonInit.on {
         [weak self] in
         DispatchQueue.main.async {
            self?.collectionView?.reloadData()
         }
      }
   }

   private func animateFromCenter() {
      if let container = imageContainer,
         let cartoonView = container.subviews.first,
         let imgView = animatedImageView {

         // Convert back to the cartoon element's frame
         let frame = container.convert(imgView.frame, from: imgView.coordinateSpace)

         UIView.animate(withDuration: 0.5, animations: {
            cartoonView.frame = frame
         }, completion: {
            _ in
            cartoonView.removeFromSuperview()
            // Make sure that you can interact with the cartoon elements again
            container.isUserInteractionEnabled = false
         })
      }
   }

   private func animateToCenter(imageView: UIImageView?) {

      guard let container = imageContainer,
            let imgView = imageView,
            let img = imgView.image else {
         return
      }

      animatedImageView = imgView

      container.isUserInteractionEnabled = true
      container.layoutIfNeeded()

      let tgr = UITapGestureRecognizer(target: self, action: #selector(handleTap(tgr:)))
      let animatedView = UIImageView(image: img)
      // Convert the frame to the center of the container, then animate it
      animatedView.frame = container.convert(imgView.frame, from: imgView.coordinateSpace)
      animatedView.contentMode = .scaleAspectFit

      container.addSubview(animatedView)

      animatedView.snp.makeConstraints {
         m in
         m.centerX.equalToSuperview()
         // Place center on top of bottom safe area
         m.centerY.equalToSuperview().offset(-(UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0))
         m.width.equalToSuperview().inset(inset)
         m.height.equalToSuperview().inset(inset)
      }

      container.setNeedsUpdateConstraints()

      UIView.animate(withDuration: 0.5, animations: {
         //animatedView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
         container.layoutIfNeeded()
      }, completion: {
         _ in
         // Add the tap recognizer when the animation is completed,
         //    so that all interaction fails until it is time
         container.addGestureRecognizer(tgr)
      })
   }

   @objc
   func handleTap(tgr: UITapGestureRecognizer) {
      if tgr.state == .ended {
         animateFromCenter()
      }
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
         animateToCenter(imageView: c.cartoonImage)
      }
   }
}
