//
//  AppDelegate.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

import AWSDynamoDB
import AWSMobileHubHelper
import FBSDKCoreKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var fetchStatuses = [
        CloudPinStatus.dynamoDBTableName(): false,
        CloudPin.dynamoDBTableName(): false,
        CloudWaypoint.dynamoDBTableName(): false
    ] {
        didSet {
            for (_, fetchComplete) in fetchStatuses {
                if !fetchComplete {
                    return
                }
            }
            writeDataToCache()
        }
    }
    
    var fetchData = [String: [AWSDynamoDBObjectModel]]()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        handleRealmMigrations()
        
        if CacheTransaction.cacheHasExpired(cacheType: .PublicPinStatuses) {
            // if no caches were performed within the expiration interval, update the cache
            
            let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            
            let openPinScanExpression = AWSDynamoDBScanExpression()
            openPinScanExpression.limit = 50
            
            objectMapper.scan(CloudPinStatus.self, expression: openPinScanExpression) { response, error in
                
                guard let response = response else {
                    print("no response")
                    return
                }
                
                guard let pinStatuses = response.items as? [CloudPinStatus] else {
                    return
                }
                
                self.fetchData[LocalPinStatus.className()] = pinStatuses
                self.fetchStatuses[CloudPinStatus.dynamoDBTableName()] = true
                
                var pinQueryInfo = [String: String]()
                pinStatuses.map{$0.pinId}.enumerate().forEach {
                    pinQueryInfo[":id\($0.index)"] = $0.element
                }
                
                let pinScanExpression = AWSDynamoDBScanExpression()
                pinScanExpression.filterExpression = "#id IN (\(pinQueryInfo.keys.joinWithSeparator(",")))"
                pinScanExpression.expressionAttributeNames = ["#id": "id",]
                pinScanExpression.expressionAttributeValues = pinQueryInfo
                
                objectMapper.scan(CloudPin.self, expression: pinScanExpression) { response, error in
                    
                    guard let response = response else {
                        print("no response: \(error)")
                        return
                    }
                    
                    guard let pins = response.items as? [CloudPin] else {
                        return
                    }
                    
                    self.fetchData[LocalPin.className()] = pins
                    self.fetchStatuses[CloudPin.dynamoDBTableName()] = true
                }
                
                var waypointQueryInfo = [String: String]()
                pinStatuses.map{$0.waypointId}.enumerate().forEach {
                    waypointQueryInfo[":id\($0.index)"] = $0.element
                }
                
                let waypointScanExpression = AWSDynamoDBScanExpression()
                waypointScanExpression.filterExpression = "#id IN (\(waypointQueryInfo.keys.joinWithSeparator(",")))"
                waypointScanExpression.expressionAttributeNames = ["#id": "id",]
                waypointScanExpression.expressionAttributeValues = waypointQueryInfo
                
                objectMapper.scan(CloudWaypoint.self, expression: waypointScanExpression) { response, error in
                    
                    guard let response = response else {
                        print("no response: \(error)")
                        return
                    }
                    
                    guard let waypoints = response.items as? [CloudWaypoint] else {
                        return
                    }
                    
                    self.fetchData[LocalWaypoint.className()] = waypoints
                    self.fetchStatuses[CloudWaypoint.dynamoDBTableName()] = true
                }
            }
        }
        
        return AWSMobileClient.sharedInstance.didFinishLaunching(application, withOptions: launchOptions)
    }
    
    func writeDataToCache() {
        let realmClassTypes: [String: Object.Type] = [
            LocalPinStatus.className(): LocalPinStatus.self,
            LocalPickup.className(): LocalPickup.self,
            LocalPin.className(): LocalPin.self,
            LocalWaypoint.className(): LocalWaypoint.self,
        ]
        
        let syncer = Syncer()
        fetchData.forEach {
            syncer.writeToLocal(realmClassTypes[$0.0]!, cloudRepresentations: $0.1)
        }
        
        CacheTransaction.markCacheUpdated(cacheType: .PublicPinStatuses)
    }
    
    func handleRealmMigrations() {
        
        let config = Realm.Configuration(
            schemaVersion: 0,
            
            migrationBlock: { migration, oldSchemaVersion in
                
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        let realm = try! Realm()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

