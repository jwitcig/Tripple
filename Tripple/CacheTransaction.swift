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
    case PublicPinStatuses  // PinStatuses, Pins, and Waypoints [public, potentially limited]
    case PinWaypoints       // Waypoints for a specific pin [note: _pinId]
    case PersonalPickups    // Pickups for a specific user [note: _userId]
}

class CacheTransaction: Object {
    dynamic var _timestamp = Int(NSDate().timeIntervalSince1970)
    dynamic var _cacheType = ""
    dynamic var _note = ""

    static let expirationInterval = NSTimeInterval(60 * 3) // 3 minutes
   
    var time: NSDate {
        return NSDate(timeIntervalSince1970: Double(_timestamp))
    }
    
    var expired: Bool {
        return NSDate().timeIntervalSinceDate(time) > CacheTransaction.expirationInterval
    }
    
    override static func primaryKey() -> String? {
        return "_timestamp"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["expirationInterval", "expired", "time"]
    }
    
    static func cacheHasExpired(cacheType cacheType: CacheTransactionType, note: String? = nil) -> Bool {
        let acceptableCacheTime = Int(NSDate().dateByAddingTimeInterval(-CacheTransaction.expirationInterval).timeIntervalSince1970)
        
        let queryset = try! Realm().objects(CacheTransaction.self)
                                   .filter("_timestamp > %@", acceptableCacheTime)
                                   .filter("_cacheType = %@", cacheType.rawValue)
        
        if let cacheNote = note {
            queryset.filter("_note = %@", cacheNote)
        }
        
        return queryset.count == 0
        
    }
    
    static func markCacheUpdated(cacheType cacheType: CacheTransactionType, note: String = "") {
        let cacheTransaction = CacheTransaction()
        cacheTransaction._cacheType = cacheType.rawValue
        cacheTransaction._note = note
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(cacheTransaction)
        }
    }

}
