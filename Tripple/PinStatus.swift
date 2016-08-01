//
//  PinStatus.swift
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

protocol PinStatus {
    var pinId: String { get set }
    var waypointId: String { get set }
}

protocol LocalPinStatusModel: PinStatus {
    var _pinId: String { get set }
    var _waypointId: String { get set }
    
    var _id: String { get set }
    
    mutating func updateId()
}

protocol CloudPinStatusModel: PinStatus {
    var _pinId: String? { get set }
    var _waypointId: String? { get set }
}

extension PinStatus {
    init() {
        self.init()
    }
}

extension LocalPinStatusModel {
    var pinId: String {
        get { return _pinId ?? "" }
        set {
            _pinId = newValue
            updateId()
        }
    }
    var waypointId: String {
        get { return _waypointId ?? "" }
        set {
            _waypointId = newValue
            updateId()
        }
    }
    
    mutating func updateId() {
        self._id = "\((pinId + waypointId).hashValue)"
    }
}

extension CloudPinStatusModel {
    var pinId: String {
        get { return _pinId ?? "" }
        set { _pinId = newValue }
    }
    var waypointId: String {
        get { return _waypointId ?? "" }
        set { _waypointId = newValue}
    }
}

class LocalPinStatus: Object, LocalPinStatusModel {
    dynamic var _pinId = ""
    dynamic var _waypointId = ""
    
    dynamic var _id = ""
    
    override static func primaryKey() -> String? {
        return "_id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["pinId", "waypointId"]
    }
}

class CloudPinStatus: AWSDynamoDBObjectModel, AWSDynamoDBModeling, CloudPinStatusModel {
    var _pinId: String?
    var _waypointId: String?
    
    class func dynamoDBTableName() -> String {

        return "tripple-mobilehub-1169331636-PinStatus"
    }
    
    class func hashKeyAttribute() -> String {

        return "_pinId"
    }
    
    override class func JSONKeyPathsByPropertyKey() -> [NSObject : AnyObject] {
        return [
               "_pinId" : "pinId",
               "_waypointId" : "waypointId",
        ]
    }
}
