//
//  Pickup.swift
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

import Foundation
import UIKit

import AWSDynamoDB
import RealmSwift

protocol Pickup {
    var userId: String { get set }
    var pinId: String { get set }
    var waypointId: String { get set }

    var createdDate: NSDate { get set }
    var pickupTime: NSDate { get set }
}

protocol LocalPickupModel: Pickup {
    var id: String { get set }
    var _userId: String { get set }
    var _pinId: String { get set }
    var _waypointId: String { get set }
    var _timestamp: Int { get set }
    
    func updateId()
}

protocol CloudPickupModel: Pickup {
    var _userId: String? { get set }
    var _pinId: String? { get set }
    var _waypointId: String? { get set }
    var _timestamp: NSNumber? { get set }
}

extension Pickup {
    init() {
        self.init()
    }
}

extension LocalPickupModel {
    var userId: String {
        get { return _userId ?? "" }
        set { _userId = newValue }
    }
    var pinId: String {
        get { return _pinId ?? "" }
        set {
            _pinId = newValue
            updateId()
        }
    }
    var waypointId: String {
        get { return _waypointId }
        set {
            _waypointId = newValue
            updateId()
        }
    }
    
    var createdDate: NSDate {
        get {
            return NSDate(timeIntervalSince1970: Double(_timestamp))
        }
        set {
            _timestamp = Int(newValue.timeIntervalSince1970)
        }
    }
    
    var pickupTime: NSDate {
        get { return createdDate }
        set { createdDate = newValue }
    }
}

extension CloudPickupModel {
    var userId: String {
        get { return _userId ?? "" }
        set { _userId = newValue }
    }
    var pinId: String {
        get { return _pinId ?? "" }
        set { _pinId = newValue }
    }
    var waypointId: String {
        get { return _waypointId ?? "" }
        set { _waypointId = newValue }
    }
    
    var createdDate: NSDate {
        get {
            if let interval = _timestamp {
                return NSDate(timeIntervalSince1970: interval.doubleValue)
            }
            return NSDate()
        }
        set {
            _timestamp = NSNumber(double: newValue.timeIntervalSince1970)
        }
    }
    var pickupTime: NSDate {
        get { return createdDate }
        set { createdDate = newValue }
    }
}

class LocalPickup: Object, LocalPickupModel {
    dynamic var _userId = ""
    dynamic var _pinId = ""
    dynamic var _waypointId = ""
    dynamic var _timestamp = 0
    
    dynamic var id = ""
    
    func updateId() {
        self.id = "\((pinId + waypointId).hashValue)"
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["userId", "pinId", "waypointId", "timestamp"]
    }
}


class CloudPickup: AWSDynamoDBObjectModel, AWSDynamoDBModeling, CloudPickupModel {
    var _userId: String?
    var _pinId: String?
    var _waypointId: String?
    var _timestamp: NSNumber?
    
    class func dynamoDBTableName() -> String {

        return "tripple-mobilehub-1169331636-Pickup"
    }
    
    class func hashKeyAttribute() -> String {

        return "_pinId"
    }
    
    class func rangeKeyAttribute() -> String {

        return "_waypointId"
    }
    
    override class func JSONKeyPathsByPropertyKey() -> [NSObject : AnyObject] {
        return [
               "_pinId" : "pinId",
               "_waypointId" : "waypointId",
               "_timestamp" : "timestamp",
               "_userId" : "userId",
        ]
    }
    
    static func ignoreAttributes() -> [String] {
        return ["createdDate", "pickupTime"]
    }
    
    // additions

    override init() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: ()) throws {
        try super.init(dictionary: dictionaryValue, error: error)
    }
    
//    convenience init(pin: Pin, waypoint: Waypoint, userId: String) {
//        self.init()
//        
//        self._pinId = pin._id
//        self._waypointId = waypoint._id
//        self._userId = userId
//        self.createdDate = NSDate()
//    }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

}
