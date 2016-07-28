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

struct MapItem {
    let waypoint: Waypoint
    let annotation: MKPointAnnotation
    
    init (waypoint: Waypoint, annotation: MKPointAnnotation) {
        self.waypoint = waypoint
        self.annotation = annotation
    }
}

class ViewWaypointsController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    let locationManager = CLLocationManager()
    
    var mapItems = [MapItem]()
    
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
            
            let waypoints = records.map { Waypoint(location: $0.valueForKey("location")! as! CLLocation) }
            
            self.mapItems = waypoints.map {
                let annotation = MKPointAnnotation()
                annotation.title = "Waypoint"
                annotation.coordinate = $0.location.coordinate
                return MapItem(waypoint: $0, annotation: annotation)
            }
            
            if let waypoint = waypoints.first {
                let region = MKCoordinateRegion(center: waypoint.location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
                self.mapView.setRegion(region, animated: true)
                
                self.shouldJumpToMyLocation = false
            }
            
            self.mapView.addAnnotations(self.mapItems.map{$0.annotation})
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

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        let id = WaypointAnnotationView.reuseIdentifier!
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(id)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            annotationView!.image = UIImage(named: "mapPin")
            annotationView!.canShowCallout = true
        } else {
            //we are re-using a view, update its annotation reference...
            annotationView!.annotation = annotation
        }
        
        annotationView?.detailCalloutAccessoryView = nil
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        let selectedAnnotation = mapItems.filter {
            if let annotation = view.annotation as? MKPointAnnotation {
                return $0.annotation == annotation
            }
            return false
        }.first
        
        guard let mapItem = selectedAnnotation else { return }
    
        print(mapItem)
    }
    
}

