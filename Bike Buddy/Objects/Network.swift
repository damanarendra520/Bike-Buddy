//
//  Network.swift
//  Bike Buddy
//
//  Created by Narendra Dama on 11/8/19.
//  Copyright © 2019 Narendra Dama. All rights reserved.
//

import Foundation


struct GeocodingServices:Decodable{
    var network:GeocodingResults
}
struct GeocodingResults:Decodable{
    let href: String
    let id: String
    let stations:[stations]
    struct stations:Decodable{
        let latitude:Float
        let longitude:Float
        let name: String
        let empty_slots: Int
        let free_bikes: Int
    }
}
