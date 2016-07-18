//
//  Waypoint.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreLocation
import Foundation

class Waypoint {
    
    var location: CLLocation
    var previousWaypoint: Waypoint?
    
    init (location: CLLocation, previousWaypoint: Waypoint? = nil) {
        self.location = location
    }
    
}