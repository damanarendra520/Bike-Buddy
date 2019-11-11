//
//  Networks.swift
//  Bike Buddy
//
//  Created by Narendra Dama on 11/8/19.
//  Copyright © 2019 Narendra Dama. All rights reserved.
//

import Foundation

struct GeocodingService:Decodable{
    var networks:[GeocodingResult]
}

struct GeocodingResult:Decodable{
    struct Location:Decodable{
        let latitude:Float
        let longitude:Float
        let city: String
        let country: String
    }
    let location:Location
    let href: String
    let id: String
}
