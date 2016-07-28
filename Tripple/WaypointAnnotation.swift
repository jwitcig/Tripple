//
//  WaypointAnnotation.swift
//  Tripple
//
//  Created by Developer on 7/19/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

class WaypointAnnotation: NSObject, MKAnnotation {

    @objc var coordinate: CLLocationCoordinate2D
    
    var title: String?
    var subtitle: String?
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }

}
