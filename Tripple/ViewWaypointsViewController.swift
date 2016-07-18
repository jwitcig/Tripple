//
//  SecondViewController.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import MapKit
import UIKit

class ViewWaypointsController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!

    let locationManager = CLLocationManager()
    
    var waypoints = [Waypoint]()
    
    var shouldJumpToMyLocation = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        let query = CKQuery(recordType: "Waypoint", predicate: NSPredicate(value: true))
        CKContainer.defaultContainer().publicCloudDatabase.performQuery(query, inZoneWithID: nil) { (records, error) in
            
            guard error == nil else {
                print("Error fetching Waypoint records: \(error!)")
                return
            }
            
            guard let records = records else { return }
            
            self.waypoints = records.map { Waypoint(location: $0.valueForKey("location")! as! CLLocation) }
            
            
            let waypoint = self.waypoints.first!
            
            
            let region = MKCoordinateRegion(center: waypoint.location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
            self.mapView.setRegion(region, animated: true)
            
            self.shouldJumpToMyLocation = false
        }
    }
    
    @IBAction func goToMyLocation(sender: AnyObject) {
        shouldJumpToMyLocation = true
        
        locationManager.requestLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else { return }
        
        if shouldJumpToMyLocation {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8))
            self.mapView.setRegion(region, animated: true)
            
            shouldJumpToMyLocation = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error updating location: \(error)")
    }

}

