//
// Created by Thomas Amundsen on 2019-03-24.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import Cache

class StorageManager {

   static let RootCartoonKey = "rootCartoonKey"

   let storage: Storage<CartoonModel>?

   private static var currentInstance: StorageManager?
   static var instance: StorageManager {
      get {
         if let ins = currentInstance {
            return ins
         }
         currentInstance = StorageManager()
         return currentInstance!
      }
   }

   init() {
      let diskConfig = DiskConfig(name: "Floppy")
      let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)

      storage = try? Storage(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: CartoonModel.self)
      )
   }

   // Store cartoon to device if it does not exist already
   func storeCartoon(model: CartoonModel, forKey key: String? = nil) {

      guard let storageKey = key == nil ? model.number == nil ? nil : String(model.number!) : key else {
         return
      }
      if let _ = getCartoon(forKey: storageKey) {
         return
      }
      do {
         try storage?.setObject(model, forKey: storageKey)
      } catch (let exception) {
         print("storeCartoon(\(key))", "Could not store cartoon: \(exception)")
      }
   }

   func getCartoon(forKey key: String) -> CartoonModel? {
      do {
         return try storage?.object(forKey: key)
      } catch(let exception) {
         print("getCartoon(\(key))", "Could not get cartoon: \(exception)")
         return nil
      }
   }
   func getCartoon(byNumber number: Int) -> CartoonModel? {
      return getCartoon(forKey: String(number))
   }

   // Store cartoon image to device if it does not exist already
   func storeCartoonImage(byNumber number: Int, image: UIImage) {
      if let _ = getCartoonImage(byNumber: number) {
         return
      }
      if let imageStore = storage?.transformImage() {
         try? imageStore.setObject(image, forKey: String(number))
      }
   }

   func getCartoonImage(byNumber number: Int) -> UIImage? {
      if let imageStore = storage?.transformImage() {
         return try? imageStore.object(forKey: String(number))
      }
      return nil
   }
}