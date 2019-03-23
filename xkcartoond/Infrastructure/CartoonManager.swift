//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

class CartoonNumberTooHighError: Error { }

class CartoonManager {

   private let baseUrl: String
   private let urlSuffix: String

   var currentCartoonModel: CartoonModel?
   var cartoonModels: Array<CartoonModel>

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

   init() {
      baseUrl = "https://xkcd.com/"
      urlSuffix = "info.0.json"
      cartoonModels = Array.init()
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

   private var numCartoons: Int? {
      get {
         return currentCartoonModel?.number
      }
   }

   private var numCachedCartoons: Int {
      get {
         return cartoonModels.count
      }
   }

   private func getCartoonUrl(_ num: Int? = nil) -> String {
      let cartoonNumber = num != nil ? "\(num!)/" : ""
      return "\(baseUrl)\(cartoonNumber)\(urlSuffix)"
   }

   func loadCartoon(withNumber num: Int?, completion: @escaping (CartoonModel?, Error?) -> Void) {
      if let nc = numCartoons, let n = num {
         if nc < n {
            completion(nil, CartoonNumberTooHighError())
            return
         }
      }
      loadCartoon(withUrl: getCartoonUrl(num), completion: completion)
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