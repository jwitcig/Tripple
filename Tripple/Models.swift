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

class Pin: Equatable, Hashable {
    
    var hashValue: Int {
        return self.id.hash
    }
    
    let id: String
    
    var title: String
    var message: String?
        
    var currentEvent: Event

    var timestamp = Date()
    
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
        
        guard let value = snapshot.value as? NSDictionary else { fatalError() }
        
        self.title = value["title"] as! String
        self.message = value["message"] as? String
        self.timestamp = Date(timeIntervalSince1970: value["timestamp"] as! Double)
        self.userID = value["userID"] as! String
        self.currentEvent = Event(snapshot: snapshot.childSnapshot(forPath: "currentEvent"))
    }
    
    init(id: String = UUID().uuidString, userID: String, currentEvent: Event, title: String, message: String? = nil) {
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

    var createdDate = Date()

    var type: String
    
    var userID: String
    
    var dictionary: NSDictionary {
        let dictionaryRepresentation: NSMutableDictionary = [
//            "location": location,
            "createdDate": createdDate.timeIntervalSince1970,
            "type": type,
            "userID": userID,
        ]
        dictionaryRepresentation.setValue(previousEventID, forKey: "previousEventID")
        return dictionaryRepresentation
    }

    init(snapshot: FIRDataSnapshot) {
        self.id = snapshot.key
        
        guard let value = snapshot.value as? NSDictionary else { fatalError() }
        
        if let location = value["location"] as? CLLocation {
            self.location = location
        } else {
            self.location = CLLocation()
        }
        self.createdDate = Date(timeIntervalSince1970: value["createdDate"] as! TimeInterval)
        self.previousEventID = value["previousEventID"] as? String
        self.type = value["type"] as! String
        self.userID = value["userID"] as! String
    }
    
    init(id: String = UUID().uuidString, pinID: String, location: CLLocation, type: String, userID: String, previousEventID: String? = nil) {
        self.id = id
        self.location = location
        self.type = type
        self.userID = userID
        self.previousEventID = previousEventID
    }
}
