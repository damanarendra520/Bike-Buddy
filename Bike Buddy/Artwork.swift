//
//  Artwork.swift
//  Bike Buddy
//
//  Created by Narendra Dama on 11/8/19.
//  Copyright © 2019 Narendra Dama. All rights reserved.
//

import MapKit

class Artwork: NSObject, MKAnnotation {
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D
    
    init(locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
}
