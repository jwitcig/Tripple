//
//  Syncer.swift
//  Tripple
//
//  Created by Developer on 7/30/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import Foundation

import AWSDynamoDB
import AWSMobileHubHelper
import RealmSwift

struct Syncer {
    
    init() { }
    
    let operationQueue = NSOperationQueue()
    
    var _realm: Realm?
    var realm: Realm {
        return try! (_realm ?? Realm())
    }
    
    func updateLocal<T: Object>(realmClass: T.Type, primaryKey: String, updateBlock: ((object: T)->()), completionHandler: ((realm: Realm)->())? = nil) {
        
        operationQueue.addOperationWithBlock {
            if let object = self.realm.objectForPrimaryKey(realmClass, key: primaryKey) {
                try! self.realm.write {
                    updateBlock(object: object)
                    
                    self.realm.add(object, update: true)
                }
            }
            completionHandler?(realm: self.realm)
        }
    }
    
    func writeToLocal<T: Object>(realmClass: T.Type, cloudRepresentations: [AWSDynamoDBObjectModel], completionHandler: ((realm: Realm)->())? = nil) {
        
        operationQueue.addOperationWithBlock {
            let cleanedRepresentations: [AnyObject] = cloudRepresentations.map {
                var cleaned = $0.dictionaryValue
                
                if let value = cleaned["_timestamp"] as? Double {
                    cleaned["_timestamp"] = Int(value)
                }
                return cleaned
            }
            
            try! self.realm.write {
                cleanedRepresentations.forEach {
                    var object: T
                    
                    switch realmClass {
                    case is LocalPin.Type:
                        let pin = LocalPin(value: $0)
                        pin.updateId()
                        object = pin as! T
                    case is LocalEvent.Type:
                        let event = LocalEvent(value: $0)
                        event.updateId()
                        object = event as! T
                    default:
                        self.realm.create(realmClass, value: $0, update: true)
                        return
                    }
                    
                    self.realm.add(object, update: true)
                }
            }
            completionHandler?(realm: self.realm)
        }
    }
    
    func syncUsersInteractions() {
        guard let userId = AWSIdentityManager.defaultIdentityManager().identityId else {
            return
        }
        
        if CacheTransaction.cacheHasExpired(cacheType: .UserData, note: userId) {
            let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            
            let pickupsScanExpression = AWSDynamoDBScanExpression()
            pickupsScanExpression.filterExpression = "#currentEventUserId = :currentEventUserId"
            pickupsScanExpression.expressionAttributeNames = ["#currentEventUserId": "currentEventUserId"]
            pickupsScanExpression.expressionAttributeValues = [":currentEventUserId": AWSIdentityManager.defaultIdentityManager().identityId!]
            
            mapper.scan(CloudPin.self, expression: pickupsScanExpression) { response, error in
                guard let response = response else {
                    print("no response")
                    return
                }
                
                guard let pins = response.items as? [CloudPin] else { return }
                
                let eventsExpression = AWSDynamoDBQueryExpression()
                eventsExpression.keyConditionExpression = "#userId = :userId"
                eventsExpression.expressionAttributeNames = ["#userId": "userId"]
                eventsExpression.expressionAttributeValues = [":userId": AWSIdentityManager.defaultIdentityManager().identityId!]
                
                mapper.query(CloudEvent.self, expression: eventsExpression) { response, error in
                    guard let response = response else {
                        print("no response")
                        return
                    }
                    
                    guard let events = response.items as? [CloudEvent] else { return }
                    
                    self.writeToLocal(LocalPin.self, cloudRepresentations: pins)
                    self.writeToLocal(LocalEvent.self, cloudRepresentations: events)

                    CacheTransaction.markCacheUpdated(cacheType: .UserData, note: userId)
                }
                
            }
        }
    }
    
    
}
