//
//  Models.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreLocation
import Foundation

//class Pin: Equatable, Hashable {
//    
//    var hashValue: Int {
//        return self.id.hash
//    }
//    
//    private var _id = NSUUID().UUIDString
//    var id: String {
//        return _id
//    }
//    
//    var title: String?
//    var message: String?
//    
//    init (title: String? = nil, message: String? = nil) {
//        self.title = title
//        self.message = message
//    }
//}
//
//func ==(lhs: Pin, rhs: Pin) -> Bool {
//    return lhs.hashValue == rhs.hashValue
//}
//
//class Waypoint {
//    var pin: Pin
//    var previousWaypoint: Waypoint?
//    
//    var location: CLLocation
//    
//    init(pin: Pin, location: CLLocation, previousWaypoint: Waypoint? = nil) {
//        self.pin = pin
//        self.location = location
//        
//        if let previousWaypoint = previousWaypoint {
//            if previousWaypoint.pin.id == pin.id {
//                self.previousWaypoint = previousWaypoint
//            }
//        }
//    }
//    
//}