//
//  CacheTransaction.swift
//  Tripple
//
//  Created by Developer on 8/1/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

import RealmSwift

enum CacheTransactionType: String {
    case PinEvents          // Events for a specific pin [note: _pinId]
    case UserData           // Pins and Events created by user [note: _userId]
    case PublicPins         // Public Pins and their current Event
}

class CacheTransaction: Object {
    dynamic var _timestamp = Int(Date().timeIntervalSince1970)
    dynamic var _cacheType = ""
    dynamic var _note = ""

<<<<<<< HEAD
    static let expirationInterval = NSTimeInterval(30) // 30 sec
=======
    static let expirationInterval = TimeInterval(60 * 3) // 3 minutes
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
   
    var time: Date {
        return Date(timeIntervalSince1970: Double(_timestamp))
    }
    
    var expired: Bool {
        return Date().timeIntervalSince(time) > CacheTransaction.expirationInterval
    }
    
    override static func primaryKey() -> String? {
        return "_timestamp"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["expirationInterval", "expired", "time"]
    }
    
<<<<<<< HEAD
    static func cacheHasExpired(cacheType cacheType: CacheTransactionType, note: String? = nil, realm: Realm? = nil) -> Bool {
        let acceptableCacheTime = Int(NSDate().dateByAddingTimeInterval(-CacheTransaction.expirationInterval).timeIntervalSince1970)
=======
    static func cacheHasExpired(cacheType: CacheTransactionType, note: String? = nil) -> Bool {
        let acceptableCacheTime = Int(Date().addingTimeInterval(-CacheTransaction.expirationInterval).timeIntervalSince1970)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        
        let queryset = try! (realm ?? Realm()).objects(CacheTransaction.self)
                                   .filter("_timestamp > %@", acceptableCacheTime)
                                   .filter("_cacheType = %@", cacheType.rawValue)
        
        if let cacheNote = note {
            queryset.filter("_note = %@", cacheNote)
        }
        
        return queryset.count == 0
    }
    
<<<<<<< HEAD
    static func markCacheUpdated(cacheType cacheType: CacheTransactionType, note: String = "", realm customRealm: Realm? = nil) {
        
        let realm = try! customRealm ?? Realm()
        
=======
    static func markCacheUpdated(cacheType: CacheTransactionType, note: String = "") {
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        let cacheTransaction = CacheTransaction()
        cacheTransaction._cacheType = cacheType.rawValue
        cacheTransaction._note = note
        
        try! realm.write {
            realm.add(cacheTransaction)
        }
    }

}
