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

   var cartoonsEvent: Event<Int>
   private var dataRequests: Dictionary<String, DataRequest>
   private(set) var numCartoons: Int?

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
         if let c = StorageManager.instance.getCartoon(byNumber: number) {
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
      cartoonsEvent = Event()
      dataRequests = Dictionary()
   }

   func setup() {

      // Load current cartoon
      loadCartoon(withNumber: nil) {
         [weak self] cm, err in

         // Ops, something went wrong.. Are you offline?
         // TODO: Add check if the error was raised due to connectivity
         if let e = err {
            print("setup()", "Error=\(e)")
            self?.trySetupOffline()
         }
         else if let cartoonModel = cm {
            // Set the maximum number of existing cartoons
            self?.numCartoons = cartoonModel.number

            // Store another reference to the root cartoon (representing the latest published one)
            StorageManager.instance.storeCartoon(model: cartoonModel,
                  forKey: StorageManager.RootCartoonKey)
         }
      }
   }

   func trySetupOffline() {
      if let cached = StorageManager.instance.getCartoon(forKey: StorageManager.RootCartoonKey) {
         numCartoons = cached.number
         cartoonsEvent.emit(cached.number ?? 0) // Manually trigger data source reload
         return
      }
   }

   private func getCartoonUrl(_ num: Int? = nil) -> String {
      let cartoonNumber = num != nil ? "\(num!)/" : ""
      return "\(baseUrl)\(cartoonNumber)\(urlSuffix)"
   }

   private func storeCartoon(model: CartoonModel?) {

      // We're dependent on the number
      guard let mod = model,
            let num = mod.number else {
         return
      }
      // Only store if it does not exist
      if StorageManager.instance.getCartoon(byNumber: num) == nil {
         StorageManager.instance.storeCartoon(model: mod)
      }
      // Trigger the data source to reload
      cartoonsEvent.emit(num)
   }

   func loadCartoon(withNumber number: Int?, completion: ((CartoonModel?, Error?) -> Void)? = nil) {
      if let num = number {
         if let nc = numCartoons {
            // There does not exist any cartoon with this number identifier yet
            if nc < num {
               completion?(nil, CartoonNumberTooHighError())
               return
            }
         }

         // Check if cartoon is stored on disk already
         if let cartoon = StorageManager.instance.getCartoon(byNumber: num) {
            print("loadCartoon(\(String(describing: num)))", "Cartoon loaded from storage")
            storeCartoon(model: cartoon)
            completion?(cartoon, nil)
            return
         }
      }

      // If all above fails, request it
      let _ = requestCartoon(withNumber: number) {
         [weak self] cm, err in

         print("loadCartoon(\((String(describing: number))))", "Cartoon requested")
         self?.storeCartoon(model: cm)
         completion?(cm, err)
      }
   }

   private func requestCartoon(withNumber num: Int?, completion: @escaping (CartoonModel?, Error?) -> Void) -> DataRequest? {
      let url = getCartoonUrl(num)
      if let dr = dataRequests[url] {
         print("requestCartoon (\((String(describing: num))))", "Request processing (\(dr.progress))")
         return nil
      }
      let request = Alamofire.request(url).validate().responseObject {
         [weak self] (response: DataResponse<CartoonModel>) in

         switch response.result {
         case .success:
            print("requestCartoon (\((String(describing: num))))", "Request success")
            completion(response.result.value, nil)
         case .failure(let error):

            // Only remove request on failure, so that we can make new requests in the future
            if let s = self,
               let absoluteUrl = response.request?.url?.absoluteString {
               s.dataRequests.removeValue(forKey: absoluteUrl)
            }

            print("requestCartoon (\((String(describing: num))))", "Request failed: \(error)")
            completion(nil, error)
         }
      }
      print("requestCartoon (\((String(describing: num))))", "Request starting")
      dataRequests[url] = request
      return request
   }
}