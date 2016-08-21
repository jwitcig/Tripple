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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        handleRealmMigrations()
        
        let serviceInfo = AWSInfo.defaultAWSInfo().defaultServiceInfo("DynamoDBObjectMapper")
        
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

