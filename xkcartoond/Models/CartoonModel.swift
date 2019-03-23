//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation
import ObjectMapper

class CartoonModel: NSObject, Mappable {

   var number: Int?
   var month: String?
   var year: String?
   var day: String?
   var news: String?
   var safeTitle: String?
   var transcript: String?
   var alt: String?
   var imgUrl: String?
   var title: String?
   var link: String?

   override init() {
      super.init()
   }

   convenience required init?(map: Map) {
      self.init()
   }

   func mapping(map: Map) {
      number <- map["num"]
      month <- map["month"]
      year <- map["year"]
      day <- map["day"]
      news <- map["news"]
      safeTitle <- map["safe_title"]
      transcript <- map["transcript"]
      alt <- map["alt"]
      imgUrl <- map["img"]
      title <- map["title"]
      link <- map["link"]
   }
}