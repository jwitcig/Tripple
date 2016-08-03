//
//  Syncer.swift
//  Tripple
//
//  Created by Developer on 7/30/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import Foundation

import AWSDynamoDB
import RealmSwift

struct Syncer {

    let realm = try! Realm()

    init() {
        
    }
    
    func writeToLocal<T: Object>(realmClass: T.Type, cloudRepresentations: [AWSDynamoDBObjectModel]) -> [T] {
        
        let cleanedRepresentations: [AnyObject] = cloudRepresentations.map {
            var cleaned = $0.dictionaryValue
            
            if let value = cleaned["_timestamp"] as? Double {
                cleaned["_timestamp"] =  Int(value)
            }
            return cleaned
        }
        
        var localObjects: [T]!
        try! realm.write {
            localObjects = cleanedRepresentations.map {
                realm.create(realmClass.self, value: $0, update: true)
            }
        }
        return localObjects
    }
}
