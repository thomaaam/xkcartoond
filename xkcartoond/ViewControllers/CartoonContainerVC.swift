//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import EmitterKit

// TODO: Implement the overrides (and then probably some more overrides)

class CartoonContainerVC : UICollectionViewController,
      UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {

   let inset: CGFloat = 10
   let numColumns: CGFloat = 2
   var cartoonsListener: EventListener<Int>!

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }

   init() {
      super.init(collectionViewLayout: UICollectionViewFlowLayout())
   }

   override func viewDidLoad() {
      super.viewDidLoad()

      collectionView?.prefetchDataSource = self
      collectionView?.backgroundColor = .white
      collectionView?.register(CartoonViewCell.self, forCellWithReuseIdentifier: CartoonViewCell.key)

      cartoonsListener = CartoonManager.instance.cartoonsEvent.on {
         [weak self] cm in

         print("cartoonsEvent", "Data changed. Count=\(CartoonManager.instance.numCartoons)")
         self?.collectionView?.reloadData()
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
      var cell = collectionView.dequeueReusableCell(withReuseIdentifier: CartoonViewCell.key, for: indexPath)
      if let c = cell as? CartoonViewCell {
         c.setup(index: indexPath.row)
      }
      return cell
   }

   func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
      print("Fetch data for these indices: \(indexPaths)")
      for i in 0..<indexPaths.count {
         let _ = CartoonManager.getCartoon(fromDictByIndex: indexPaths[i].row)
      }
   }
}