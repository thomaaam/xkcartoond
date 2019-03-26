//
// Created by Thomas Amundsen on 2019-03-25.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage
import EmitterKit

class ImageManager {

   private static var currentInstance: ImageManager?

   private var imageEvents: Dictionary<String, Event<UIImage>>
   private let imageDownloader: ImageDownloader

   static let instance = ImageManager()

   init(maximumActiveDownloads: Int = 8) {

      imageDownloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: .lifo, // Last downloaded images first
            maximumActiveDownloads: maximumActiveDownloads,
            imageCache: AutoPurgingImageCache()
      )
      imageEvents = Dictionary()
   }

   func subscribe(byUrl url: String?, event: Event<UIImage>) {
      if let u = url {
         imageEvents[u] = event

         // Set immediately or load and possibly set later
         loadImage(url: u)
      }
   }

   func loadImage(url: String, completion: ((UIImage?, Error?) -> Void)? = nil) {
      guard let u = URL(string: url) else {
         return
      }
      // Return cached or downloaded image
      imageDownloader.download(URLRequest(url: u)) {
         [weak self] (response: DataResponse<Image>) in
         print("getImage(\(u))", response)

         if let url = response.request?.url?.absoluteString,
            let image = response.value,
            let event = self?.imageEvents[url] {

            print("getImage(\(u))", "Emit image")
            event.emit(image)
         }
         completion?(response.result.value, response.error)
      }
   }
}