//
//  MKPinInfo.swift
//  SQLiteCitySearch
//
//  Created by macbook on 3/19/18.
//  Copyright © 2018 Jaminya. All rights reserved.
//

import Foundation
import MapKit

class MKPinInfo: NSObject, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }
}
