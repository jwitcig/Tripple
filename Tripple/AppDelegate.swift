//
//  AppDelegate.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

import AWSDynamoDB
import AWSMobileHubHelper
import FBSDKCoreKit
import GeohashKitiOS
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        handleRealmMigrations()
        
        let serviceInfo = AWSInfo.defaultAWSInfo().defaultServiceInfo("DynamoDBObjectMapper")
=======
        if CacheTransaction.cacheHasExpired(cacheType: .PublicPinStatuses) {
            // if no caches were performed within the expiration interval, update the cache
            
            let objectMapper = AWSDynamoDBObjectMapper.default()
            
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
                pinStatuses.map{$0.pinId}.enumerated().forEach {
                    pinQueryInfo[":id\($0.index)"] = $0.element
                }
                
                let pinScanExpression = AWSDynamoDBScanExpression()
                pinScanExpression.filterExpression = "#id IN (\(pinQueryInfo.keys.joined(separator: ",")))"
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
                pinStatuses.map{$0.waypointId}.enumerated().forEach {
                    waypointQueryInfo[":id\($0.index)"] = $0.element
                }
                
                let waypointScanExpression = AWSDynamoDBScanExpression()
                waypointScanExpression.filterExpression = "#id IN (\(waypointQueryInfo.keys.joined(separator: ",")))"
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
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        
        if let credentialsProvider = serviceInfo?.cognitoCredentialsProvider {
            // takes credentials provider info from mobile hub configuration to setup the low level clients' auth
            AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)
        }
                
        return AWSMobileClient.sharedInstance.didFinishLaunching(application, withOptions: launchOptions)
    }
    
    func handleRealmMigrations() {
        
        let config = Realm.Configuration(
            schemaVersion: 4,
            
            migrationBlock: { migration, oldSchemaVersion in
                
                if oldSchemaVersion < 1 {
                    migration.enumerate(LocalEvent.className()) { oldObject, newObject in
                        guard let latitude = oldObject?["_latitude"] as? Double,
                            let longitude = oldObject?["_longitude"] as? Double
                            else { return }
                        
                        let location = CLLocation(latitude: latitude, longitude: longitude)
                        newObject?["_geohash"] = Geohash.encode(location: location, 12)
                    }
                }
                
                if oldSchemaVersion < 2 {
                   
                }
                
                if oldSchemaVersion < 3 {
                    
                }
                
                if oldSchemaVersion < 4 {
                    migration.renamePropertyForClass(LocalPin.className(), oldName: "_status", newName: "_pinStatus")
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        _ = try! Realm()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

