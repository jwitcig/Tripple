//
//  Waypoint.swift
//  MySampleApp
//
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.2
//

import CoreLocation
import Foundation
import UIKit

import AWSDynamoDB
import RealmSwift

protocol Waypoint {
    var userId: String { get set }
    var id: String { get set }
    var latitude: CLLocationDegrees { get set }
    var longitude: CLLocationDegrees { get set }
    var pinId: String { get set }
    var previousWaypointId: String? { get set }
    
    var createdDate: Date { get set }
}

protocol LocalWaypointModel: Waypoint {
    var _userId: String { get set }
    var _id: String { get set }
    var _latitude: Double { get set }
    var _longitude: Double { get set }
    var _pinId: String { get set }
    var _previousWaypointId: String? { get set }
    var _timestamp: Int { get set }
}

protocol CloudWaypointModel: Waypoint {
    var _userId: String? { get set }
    var _id: String? { get set }
    var _latitude: NSNumber? { get set }
    var _longitude: NSNumber? { get set }
    var _pinId: String? { get set }
    var _previousWaypointId: String? { get set }
    var _timestamp: NSNumber? { get set }
}

extension Waypoint {
    init() {
        self.init()
    }
}

extension LocalWaypointModel {
    var userId: String {
        get { return _userId ?? "" }
        set { _userId = newValue }
    }
    var id: String {
        get { return _id ?? UUID().uuidString }
        set { _id = newValue }
    }
    var latitude: CLLocationDegrees {
        get { return _latitude }
        set { _latitude = newValue }
    }
    var longitude: CLLocationDegrees {
        get { return _longitude }
        set { _longitude = newValue }
    }
    var pinId: String {
        get { return _pinId ?? "" }
        set { _pinId = newValue }
    }
    var previousWaypointId: String? {
        get { return _previousWaypointId }
        set { _previousWaypointId = newValue }
    }
    var createdDate: Date {
        get {
            return Date(timeIntervalSince1970: Double(_timestamp))
        }
        set {
            _timestamp = Int(newValue.timeIntervalSince1970)
        }
    }
}

extension CloudWaypointModel {
    var userId: String {
        get { return _userId ?? "" }
        set { _userId = newValue }
    }
    var id: String {
        get { return _id ?? UUID().uuidString }
        set { _id = newValue }
    }
    var latitude: CLLocationDegrees {
        get { return _latitude?.doubleValue ?? 0.0 }
        set { _latitude = newValue as NSNumber? }
    }
    var longitude: CLLocationDegrees {
        get { return _longitude?.doubleValue ?? 0.0 }
        set { _longitude = newValue as NSNumber? }
    }
    var pinId: String {
        get { return _pinId ?? "" }
        set { _pinId = newValue }
    }
    var previousWaypointId: String? {
        get { return _previousWaypointId }
        set { _previousWaypointId = newValue }
    }
    var createdDate: Date {
        get {
            if let interval = _timestamp {
                return Date(timeIntervalSince1970: interval.doubleValue)
            }
            return Date()
        }
        set {
            _timestamp = NSNumber(value: newValue.timeIntervalSince1970 as Double)
        }
    }
}

class LocalWaypoint: Object, LocalWaypointModel {
    dynamic var _userId = ""
    dynamic var _id = UUID().uuidString
    dynamic var _latitude: Double = 0.0
    dynamic var _longitude: Double = 0.0
    dynamic var _pinId = ""
    dynamic var _previousWaypointId: String?
    dynamic var _timestamp = 0
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["userId", "id", "latitude", "longitude", "pinId", "previousWaypointId", "timestamp"]
    }
}

class CloudWaypoint: AWSDynamoDBObjectModel, AWSDynamoDBModeling, CloudWaypointModel {
    
    var _userId: String?
    var _id: String? = UUID().uuidString
    var _latitude: NSNumber?
    var _longitude: NSNumber?
    var _pinId: String?
    var _previousWaypointId: String?
    var _timestamp: NSNumber?
    
    class func dynamoDBTableName() -> String {

        return "tripple-mobilehub-1169331636-Waypoint"
    }
    
    class func hashKeyAttribute() -> String {

        return "_userId"
    }
    
    static func rangeKeyAttribute() -> String {
        return "_id"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_userId" : "userId",
               "_id" : "id",
               "_latitude" : "latitude",
               "_longitude" : "longitude",
               "_pinId" : "pinId",
               "_previousWaypointId" : "previousWaypointId",
               "_timestamp" : "timestamp",
        ]
    }
    
    static func ignoreAttributes() -> [String] {
        return ["dropLocation", "createdDate"]
    }
    
    // additions

    var dropLocation: CLLocation {
        get {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        set {
            _latitude = NSNumber(value: newValue.coordinate.latitude as Double)
            _longitude =  NSNumber(value: newValue.coordinate.longitude as Double)
        }
    }
    
    override init() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [AnyHashable: Any]!, error: ()) throws {
        try super.init(dictionary: dictionaryValue, error: error)
    }
    
//    convenience init(pin: Pin, location: CLLocation, previousWaypoint: Waypoint? = nil) {
//        self.init()
//        
//        self._pinId = pin._id
//        self.dropLocation = location
//        self._previousWaypointId = previousWaypoint?._id
//    }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
