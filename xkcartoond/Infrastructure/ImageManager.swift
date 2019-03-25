//
// Created by Thomas Amundsen on 2019-03-25.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import AlamofireImage

class ImageManager {

   private static var currentInstance: ImageManager?

   private let imageDownloader: ImageDownloader

   static var instance: ImageManager {
      get {
         if let ins = currentInstance {
            return ins
         }
         currentInstance = ImageManager()
         return currentInstance!
      }
   }

   init(maximumActiveDownloads: Int = 16) {

      imageDownloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: .lifo, // Last downloaded images first
            maximumActiveDownloads: maximumActiveDownloads,
            imageCache: AutoPurgingImageCache()
      )
   }

   func getImage(url: String, completion: @escaping (UIImage?, Error?) -> Void) -> RequestReceipt? {
      guard let u = URL(string: url) else {
         return nil
      }

      let req = imageDownloader.download(URLRequest(url: u)) {
         response in
         print("getImage(\(u))", response)

         if let image = response.result.value {
            return
         }
      }

      return req
   }
}