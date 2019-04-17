//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import EmitterKit

// TODO:
//    (√) 1. When scrolling, make sure to cancel requests that will end in showing an image outside of the screen.
//       Only focus on the requests that eventually will be presented to the user.
//       This is really visible when scrolling fast, as we then have to wait for the previous requests to finish
//          before finally managing the relevant requests that eventually will present cartoons on screen.
//    (√) 2. "Animate to center" animation for clicked cartoons.
//    3. Add progress bar or placeholder image for cartoons that do not correspond to the requested ones.
//    4. Eventually implement/design layout for showing cartoon information (like number, date and description)
//    (DOING) 5. Implement functionality for adjusting number of items (in width) when doing a zoom in/out gesture.

class CartoonContainerVC : UICollectionViewController,
      UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {

   private let inset: CGFloat = 10

   private let minColumns: CGFloat = 1
   private let maxColumns: CGFloat = 4
   private var numColumns: CGFloat = 2 // Current number of elements (in width)

   private var cartoonsListener: EventListener<Void>!

   private var imageContainer: UIView?
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

      let container = UIView()
      container.isUserInteractionEnabled = false

      let overlay = UIView()
      overlay.alpha = 0
      overlay.backgroundColor = UIColor(white: 0.9, alpha: 0.9)
      container.addSubview(overlay)
      overlay.snp.makeConstraints {
         m in
         m.left.top.height.width.equalToSuperview()
      }

      view.addSubview(container)
      container.snp.makeConstraints {
         m in
         m.left.width.equalToSuperview()
         m.top.equalToSuperview().offset(topSafeArea + (navigationController?.navigationBar.bounds.height ?? 0))
         m.bottom.equalToSuperview()
      }

      imageContainer = container

      cartoonsListener = CartoonManager.instance.currentCartoonInit.on {
         [weak self] in
         DispatchQueue.main.async {
            self?.collectionView?.reloadData()
         }
      }

      // FIXME. Just temp for testing.
      // TODO: Should adjust number of elements by doing a zoom in/out touch gesture
      navigationController?.navigationBar.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(adjustElementSizeInWidth(tgr:))))
   }

   private func animateFromCenter() {
      if let container = imageContainer,
         let overlay = container.subviews.first,
         let cartoonView = container.subviews.first(where: { view in view is UIImageView }),
         let imgView = animatedImageView {

         // Convert back to the cartoon element's frame
         let frame = container.convert(imgView.frame, from: imgView.coordinateSpace)

         UIView.animate(withDuration: 0.5, animations: {
            cartoonView.frame = frame
            overlay.alpha = 0
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
            let overlay = container.subviews.first,
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
         m.left.top.right.equalToSuperview().inset(inset)
         m.bottom.equalToSuperview().inset(inset + bottomSafeArea)
      }

      container.setNeedsUpdateConstraints()

      UIView.animate(withDuration: 0.5, animations: {
         //animatedView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
         container.layoutIfNeeded()
         overlay.alpha = 1
      }, completion: {
         _ in
         // Add the tap recognizer when the animation is completed,
         //    so that all interaction fails until it is time
         container.addGestureRecognizer(tgr)
      })
   }


   // FIXME: Just temp for testing changing number of elements (in width)
   @objc
   func adjustElementSizeInWidth(tgr: UITapGestureRecognizer) {
      if tgr.state == .ended {
         if numColumns == maxColumns {
            numColumns = minColumns
         } else {
            numColumns += 1
         }
         collectionView?.reloadData()
      }
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

   override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
      print("didEndDisplaying(\(String(describing: indexPath.row)))")
      CartoonManager.instance.unsubscribe(byIndex: indexPath.row)
   }
}
