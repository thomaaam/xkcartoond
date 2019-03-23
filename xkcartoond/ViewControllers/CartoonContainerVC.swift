//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

// TODO: Implement the overrides (and then probably some more overrides)

class CartoonContainerVC : UICollectionViewController, UICollectionViewDelegateFlowLayout {

   let inset: CGFloat = 10
   let numColumns: CGFloat = 2

   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }

   init() {
      super.init(collectionViewLayout: UICollectionViewFlowLayout())
   }

   override func viewDidLoad() {
      super.viewDidLoad()

      collectionView?.backgroundColor = .white
      collectionView?.register(CartoonViewCell.self, forCellWithReuseIdentifier: CartoonViewCell.key)
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
      return 6 // TODO
   }

   override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      var cell = collectionView.dequeueReusableCell(withReuseIdentifier: CartoonViewCell.key, for: indexPath)
      return cell
   }
}