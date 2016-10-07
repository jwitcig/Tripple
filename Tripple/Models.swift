//
//  Models.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CoreLocation
import Foundation

import Firebase
import FirebaseDatabase

import GeoFire

class Pin: Equatable, Hashable {
    
    var hashValue: Int {
        return self.id.hash
    }
    
    let id: String
    
    var title: String
    var message: String?
    
    var currentEvent: Event

    var timestamp = NSDate()
    
    var userID: String
    
    var dictionary: NSDictionary {
        let dictionaryRepresentation: NSMutableDictionary = [
            "title": title,
            "currentEvent": currentEvent.dictionary,
            "timestamp": timestamp.timeIntervalSince1970,
            "userID": userID,
        ]
        dictionaryRepresentation.setValue(message, forKey: "message")
        return dictionaryRepresentation
    }
    
    init(snapshot: FIRDataSnapshot) {
        self.id = snapshot.key
        self.title = snapshot.value!["title"] as! String
        self.message = snapshot.value!["message"] as? String
        self.timestamp = NSDate(timeIntervalSince1970: snapshot.value!["timestamp"] as! Double)
        self.userID = snapshot.value!["userID"] as! String
        self.currentEvent = Event(snapshot: snapshot.childSnapshotForPath("currentEvent"))
    }
    
    init(id: String = NSUUID().UUIDString, userID: String, currentEvent: Event, title: String, message: String? = nil) {
        self.id = id
        self.userID = userID
        self.title = title
        self.message = message
        self.currentEvent = currentEvent
    }
}

func ==(lhs: Pin, rhs: Pin) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class Event {
    let id: String

    var previousEventID: String?
    
    var location: CLLocation

    let timestamp = NSDate()

    var type: String
    
    var userID: String
    
    var dictionary: NSDictionary {
        let dictionaryRepresentation: NSMutableDictionary = [
//            "location": location,
            "timestamp": timestamp.timeIntervalSince1970,
            "type": type,
            "userID": userID,
        ]
        dictionaryRepresentation.setValue(previousEventID, forKey: "previousEventID")
        return dictionaryRepresentation
    }

    init(snapshot: FIRDataSnapshot) {
        self.id = snapshot.key
        
        if let location = snapshot.value!["location"] as? CLLocation {
            self.location = location
        } else {
            self.location = CLLocation()
        }
        self.previousEventID = snapshot.value?["previousEventID"] as? String
        self.type = snapshot.value!["type"] as! String
        self.userID = snapshot.value!["userID"] as! String
    }
    
    init(id: String = NSUUID().UUIDString, pinID: String, location: CLLocation, type: String, userID: String, previousEventID: String? = nil) {
        self.id = id
        self.location = location
        self.type = type
        self.userID = userID
        self.previousEventID = previousEventID
    }
}