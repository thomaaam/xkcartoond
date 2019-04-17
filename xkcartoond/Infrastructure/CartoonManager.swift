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

   var currentCartoonInit: Event<Void>
   private var dataRequests: Dictionary<String, DataRequest>
   private var cartoonEvents: Dictionary<Int, Event<CartoonModel>>
   private(set) var numCartoons: Int? {
      didSet {
         currentCartoonInit.emit()
      }
   }

   static let instance = CartoonManager()

   init() {
      baseUrl = "https://xkcd.com/"
      urlSuffix = "info.0.json"
      currentCartoonInit = Event()
      dataRequests = Dictionary()
      cartoonEvents = Dictionary()
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
         return
      }
   }

   private func getNumber(byIndex index: Int) -> Int? {
      if let count = numCartoons {
         return count - index
      }
      return nil
   }

   func unsubscribe(byIndex index: Int) {
      if let number = getNumber(byIndex: index) {
         cartoonEvents.removeValue(forKey: number)

         // Cancel request immediately, as we won't show it anyways
         removeRequest(withUrl: getCartoonUrl(number))
      }
   }

   func subscribe(byIndex index: Int, event: Event<CartoonModel>) {
      if let number = getNumber(byIndex: index) {
         cartoonEvents[number] = event

         // Set immediately or load and possibly set later
         loadCartoon(withNumber: number)
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
   }

   func loadCartoon(withIndex index: Int) {
      loadCartoon(withNumber: getNumber(byIndex: index))
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
         if let cm = StorageManager.instance.getCartoon(byNumber: num) {
            print("loadCartoon(\(String(describing: num)))", "Cartoon loaded from storage")
            cartoonEvents[num]?.emit(cm)
            completion?(cm, nil)
            return
         }
      }

      // If all above fails, request it
      let _ = requestCartoon(withNumber: number) {
         [weak self] cm, err in

         print("loadCartoon(\((String(describing: number))))", "Cartoon requested")

         // Store it for faster access
         self?.storeCartoon(model: cm)

         // Return it if someone is listening
         if let num = cm?.number {
            self?.cartoonEvents[num]?.emit(cm!)
         }
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
            print("requestCartoon (\((String(describing: num))))", "Request failed: \(error)")
            self?.removeRequest(withUrl: response.request?.url?.absoluteString)
            completion(nil, error)
         }
      }
      print("requestCartoon (\((String(describing: num))))", "Request starting")
      dataRequests[url] = request
      return request
   }

   private func removeRequest(withUrl url: String?) {
      guard let u = url else { return }

      // Cancel if ongoing
      if let req = dataRequests[u] {
         if !req.progress.isFinished {
            print("removeRequest(\(u)): Cancel")
            req.cancel()
         }
      }
      // Remove request from cache, so that we can make a new one in the future
      print("removeRequest(\(u)): Remove")
      dataRequests.removeValue(forKey: u)
   }
}