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

   var currentCartoonModel: CartoonModel?
   private var cartoonModels: Dictionary<Int, CartoonModel>
   var cartoonsEvent: Event<Int>
   var lastRequestedCartoon: Int?
   let cartoonBathNumber: Int = 5
   private var dataRequests: Dictionary<String, DataRequest>

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

   static func getCartoon(fromDictByIndex index: Int) -> CartoonModel? {
      if let count = instance.numCartoons {
         let number = count - index
         if let c = instance.cartoonModels[number] {
            print("[getCartoon(\(index))]", "Returning cached \(number):\(c)")
            return c
         }
         else {
            print("[getCartoon(\(index))]", "Loading cartoon \(number)")
            instance.loadCartoon(withNumber: number)
         }
      }
      print("[getCartoon(\(index))]", "Returning nil")
      return nil
   }

   init() {
      baseUrl = "https://xkcd.com/"
      urlSuffix = "info.0.json"
      cartoonModels = Dictionary()
      cartoonsEvent = Event()
      dataRequests = Dictionary()
   }

   func setup() {
      // Load current cartoon
      loadCartoon(withNumber: nil) {
         [weak self] cm, err in
         guard let s = self else {
            return
         }
         s.currentCartoonModel = cm

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
      cartoonsEvent.emit(number)
   }

   func loadCartoon(withNumber num: Int?, completion: ((CartoonModel?, Error?) -> Void)? = nil) {
      if let nc = numCartoons, let n = num {
         if nc < n {
            completion?(nil, CartoonNumberTooHighError())
            return
         }
         lastRequestedCartoon = n
      }

      let _ = requestCartoon(withNumber: num) {
         [weak self] cm, err in

         if let cartoonModel = cm {
            self?.storeCartoon(cartoonModel)
         }
         completion?(cm, err)
      }
   }

   private func requestCartoon(withNumber num: Int?, completion: @escaping (CartoonModel?, Error?) -> Void) -> DataRequest? {
      let url = getCartoonUrl(num)
      if let dr = dataRequests[url] {
         print("requestCartoon (\(num))", "Request processing (\(dr.progress))")
         return nil
      }
      let request = Alamofire.request(url).validate().responseObject {
         [weak self] (response: DataResponse<CartoonModel>) in

         switch response.result {
         case .success:
            print("requestCartoon (\(num))", "Request success")
            completion(response.result.value, nil)
         case .failure(let error):

            // Only remove request on failure, so that we can make new requests in the future
            if let s = self,
               let absoluteUrl = response.request?.url?.absoluteString {
               s.dataRequests.removeValue(forKey: absoluteUrl)
            }

            print("requestCartoon (\(num))", "Request failed: \(error)")
            completion(nil, error)
         }
      }
      print("requestCartoon (\(num))", "Request starting")
      dataRequests[url] = request
      return request
   }
}