//
// Created by Thomas Amundsen on 2019-03-22.
// Copyright (c) 2019 Thomas Amundsen. All rights reserved.
//

import Foundation

// TODO: Set the data based on this URL:
// https://xkcd.com/<index>/info.0.json

class CartoonModel {

   var month: Int
   var year: Int
   var day: Int
   var news: String
   var safeTitle: String
   var transcript: String
   var alt: String
   var imgUrl: String
   var title: String

   init(index: Int) {
      month = 0
      year = 0
      day = 0
      news = ""
      safeTitle = ""
      transcript = ""
      alt = ""
      imgUrl = ""
      title = ""
   }
}