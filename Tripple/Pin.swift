//
//  Pin.swift
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

protocol Pin {
    var userId: String { get set }
    var id: String { get }
    var message: String? { get set }
    var title: String { get set }
    var pinStatus: String { get set }
    var geohash: String { get set }
    
    var createdDate: NSDate { get set }
}

protocol LocalPinModel: Pin {
    var _userId: String { get set }
    var _message: String? { get set }
    var _title: String { get set }
    var _timestamp: Int { get set }
    var _pinStatus: String { get set }
    var _geohash: String { get set }
}

protocol CloudPinModel: Pin {
    var _userId: String? { get set }
    var _message: String? { get set }
    var _title: String? { get set }
    var _timestamp: NSNumber? { get set }
    var _pinStatus: String? { get set }
    var _geohash: String? { get set }
    var _currentEvent: NSDictionary? { get set }
    
    func setCurrentEvent(currentEvent: Event)
}

extension Pin {
    init() {
        self.init()
    }
    
    init(title: String, message: String? = nil) {
        self.init()
        self.title = title
        self.message = message
    }
    
    var id: String {
        return "[\(userId)]\(Int(createdDate.timeIntervalSince1970))"
    }
}

extension LocalPinModel {
    var userId: String {
        get { return _userId }
        set { _userId = newValue }
    }
    var message: String? {
        get { return _message }
        set { _message = newValue }
    }
    var title: String {
        get { return _title }
        set { _title = newValue }
    }
    var pinStatus: String {
        get { return _pinStatus }
        set { _pinStatus = newValue }
    }
    var geohash: String {
        get { return _geohash }
        set { _geohash = newValue }
    }

    var createdDate: NSDate {
        get {
            return NSDate(timeIntervalSince1970: Double(_timestamp))
        }
        set {
            _timestamp = Int(newValue.timeIntervalSince1970)
        }
    }
}

extension CloudPinModel {
    var userId: String {
        get { return _userId ?? "" }
        set { _userId = newValue }
    }
    var message: String? {
        get { return _message }
        set { _message = newValue }
    }
    var title: String {
        get { return _title ?? "" }
        set { _title = newValue }
    }
    var pinStatus: String {
        get { return _pinStatus ?? "" }
        set { _pinStatus = newValue }
    }
    var geohash: String {
        get { return _geohash ?? "" }
        set { _geohash = newValue }
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
}

class LocalPin: Object, LocalPinModel {
    dynamic var _id = ""
    dynamic var _userId = "" {
        didSet { updateId() }
    }
    dynamic var _timestamp = 0 {
        didSet { updateId() }
    }
    dynamic var _title = ""
    dynamic var _message: String?
    dynamic var _pinStatus = ""
    dynamic var _geohash = ""
    
    var events: Results<LocalEvent> {
        return realm!.objects(LocalEvent).filter("_pinId == %@", id)
    }
    var currentEvent: Event? {
        get {
            return events.sorted("_timestamp", ascending: false).first
        }
        set { }
    }
    
    func updateId() {
        _id = id
    }
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["userId", "message", "title", "timestamp", "pinStatus", "geohash", "currentEvent"]
    }
}

class CloudPin: AWSDynamoDBObjectModel, AWSDynamoDBModeling, CloudPinModel  {
    var _userId: String?
    var _message: String?
    var _title: String?
    var _timestamp: NSNumber? {
        didSet { _timestamp = NSNumber(integer: _timestamp!.integerValue) }
    }
    var _pinStatus: String?
    var _geohash: String?
    var _currentEvent: NSDictionary?
    
    class func dynamoDBTableName() -> String {
        return "tripple-mobilehub-1169331636-Pin"
    }
    
    class func hashKeyAttribute() -> String {
        return "_userId"
    }
    
    class func rangeKeyAttribute() -> String {
        return "_timestamp"
    }
    
    override class func JSONKeyPathsByPropertyKey() -> [NSObject : AnyObject] {
        return [
               "_userId" : "userId",
               "_message" : "message",
               "_title" : "title",
               "_timestamp" : "timestamp",
               "_pinStatus": "pinStatus",
               "_geohash": "geohash",
               "_currentEvent": "currentEvent",
        ]
    }
    
    static func ignoreAttributes() -> [String] {
        return ["createdDate", "id"]
    }
        
    func setCurrentEvent(currentEvent: Event) {
        _currentEvent = [
            "id": currentEvent.id
        ]
    }
    
    // additions
    
    override init() {
        super.init()
    }
    
    override init(dictionary dictionaryValue: [NSObject : AnyObject]!, error: ()) throws {
        try super.init(dictionary: dictionaryValue, error: error)
    }
    
    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

}
