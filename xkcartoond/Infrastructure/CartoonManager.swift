//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import EmitterKit

class CartoonNumberTooHighError: Error { }

class CartoonManager {

   private let baseUrl: String
   private let urlSuffix: String

   var currentCartoonModel: CartoonModel? {
      didSet {
         currentCartoonEvent.emit(currentCartoonModel)
      }
   }
   private var cartoonModelsArray: Array<CartoonModel>
   private var cartoonModels: Dictionary<Int, CartoonModel>
   var cartoonsEvent: Event<Int>
   var currentCartoonEvent: Event<CartoonModel?> // TODO? Might remove this

   private static var currentInstance: CartoonManager?
   static var instance: CartoonManager {
      get {
         if let ins = currentInstance {
            return ins
         }
         currentInstance = CartoonManager()
         return currentInstance!
      }
   }

   static func getCartoon(fromDictWithIndex index: Int) -> CartoonModel? {
      return instance.cartoonModels[index]
   }
   static func getCartoon(fromArrayWithIndex index: Int) -> CartoonModel? {
      if instance.cartoonModelsArray.count <= index {
         return nil
      }
      return instance.cartoonModelsArray[index]
   }

   init() {
      baseUrl = "https://xkcd.com/"
      urlSuffix = "info.0.json"
      cartoonModels = Dictionary()
      cartoonModelsArray = Array()
      cartoonsEvent = Event()
      currentCartoonEvent = Event()
   }

   func setup() {
      // Load current cartoon
      loadCartoon(withNumber: nil) {
         [weak self] cm, err in
         self?.currentCartoonModel = cm

         if let e = err {
            // TODO: Do something?
         }
      }
   }

   var numCartoons: Int? {
      get {
         return currentCartoonModel?.number
      }
   }

   var numCachedCartoons: Int {
      get {
         return cartoonModels.count
      }
   }

   private func getCartoonUrl(_ num: Int? = nil) -> String {
      let cartoonNumber = num != nil ? "\(num!)/" : ""
      return "\(baseUrl)\(cartoonNumber)\(urlSuffix)"
   }

   // TODO: Store to device as well, then restore on startup
   private func storeCartoon(_ cartoonModel: CartoonModel) {
      // We are dependent on the cartoon number
      guard let number = cartoonModel.number else {
         return
      }
      // Already exists. Do nothing
      if let cm = cartoonModels[number] {
         return
      }
      cartoonModels.updateValue(cartoonModel, forKey: number)
      cartoonModelsArray.append(cartoonModel)
      cartoonsEvent.emit(number)
   }

   func loadCartoon(withNumber num: Int?, completion: ((CartoonModel?, Error?) -> Void)? = nil) {
      if let nc = numCartoons, let n = num {
         if nc < n {
            completion?(nil, CartoonNumberTooHighError())
            return
         }
      }
      loadCartoon(withUrl: getCartoonUrl(num)) {
         [weak self] cm, err in
         if let cartoonModel = cm {
            self?.storeCartoon(cartoonModel)
         }
         completion?(cm, err)
      }
   }

   private func loadCartoon(withUrl url: String, completion: @escaping (CartoonModel?, Error?) -> Void) {
      Alamofire.request(url).validate().responseObject { (response: DataResponse<CartoonModel>) in
         switch response.result {
         case .success:
            completion(response.result.value, nil)
         case .failure(let error):
            completion(nil, error)
         }
      }
   }
}