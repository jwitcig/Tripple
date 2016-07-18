//
//  FirstViewController.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreLocation
import UIKit

class CreateWaypointViewController: UIViewController, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()
    
    var currentLocation: CLLocation? {
        return locationManager.location
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    @IBAction func createWaypoint(sender: AnyObject) {
        // Request location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            
            // Checks for updated location 3 times
            for _ in 0..<10 {
                
                sleep(1)
                if self.currentLocation != nil {
                    // if location was updated, continue on
                    break
                }
            }
            
            if self.currentLocation == nil {
                print("unable to retrieve location")
                return
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let waypoint = Waypoint(location: self.currentLocation!)

                let record = CKRecord(recordType: "Waypoint")
                record.setValue(waypoint.location, forKey: "location")
                
                CKContainer.defaultContainer().publicCloudDatabase.saveRecord(record, completionHandler: { (record, error) in
                    
                    guard error == nil else {
                        print("Error saving record: \(error)")
                        return
                    }
                })
            })
        })
        
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Failed: \(error)")
    }
    

}

