//
//  PinViewController.swift
//  Tripple
//
//  Created by Developer on 7/31/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

import AWSDynamoDB
import AWSMobileHubHelper
import RealmSwift

struct PinItem {
    let pin: Pin
    let waypoints: Results<LocalWaypoint>
    
    var currentWaypoint: Waypoint {
        return waypoints.sort{$0.0.createdDate.compare($0.1.createdDate) == .OrderedDescending}[0]
    }
    
    init(pin: Pin, waypoints: Results<LocalWaypoint>) {
        self.pin = pin
        self.waypoints = waypoints
    }
}

class PinViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageView: UITextView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var previousLocationsStackView: UIStackView!
    
    @IBOutlet weak var pickupPinButton: UIButton!
    @IBOutlet weak var dropPinButton: UIButton!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var topColor: UIView!
    
    var locationHandler = LocationHandler()
    
    var realmNotificationToken: NotificationToken?
    
    struct WaypointInfo {
        let waypoint: Waypoint
        var placemark: CLPlacemark?
        
        init(waypoint: Waypoint, placemark: CLPlacemark?) {
            self.waypoint = waypoint
            self.placemark = placemark
        }
        
        var cityName: String? {
            return placemark?.addressDictionary?["City"] as? String
        }
    }
    
    var pin: Pin! {
        didSet {
            let waypoints = try! Realm().objects(LocalWaypoint.self).filter("_pinId == %@", pin.id)
            pinItem = PinItem(pin: pin, waypoints: waypoints)
        }
    }
    
    var pinItem: PinItem!
    
    var waypointInfoList = [WaypointInfo]()
    
    var userHoldsPin: Bool {
        let realm = try! Realm()
        let statuses = realm.objects(LocalPinStatus.self)
        let currentPickups = realm.objects(LocalPickup.self).filter("_waypointId IN %@", statuses.map{$0.waypointId})
        
        return currentPickups.filter("_pinId = %@", pin.id).first != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        realmNotificationToken = try! Realm().addNotificationBlock { notification, realm in
            dispatch_async(dispatch_get_main_queue()) {
                self.updateUI()
            }
        }
        
        navigationBar.translucent = true
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = topColor.backgroundColor
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.pickupPinButton.hidden = true

        updateUI()
        
        locationHandler.executionBlock = { location, error in
            guard let usersLocation = location else {
                print("error getting location: \(error)")
                return
            }
            
            self.locationUpdated(location: usersLocation)
        }
        
        locationHandler.requestLocation()
    }
    
    func locationUpdated(location location: CLLocation) {
        let pinLocation = CLLocation(latitude: self.pinItem.currentWaypoint.latitude, longitude: self.pinItem.currentWaypoint.longitude)
        
        let distance = location.distanceFromLocation(pinLocation) * 0.000621371 // in miles
        dispatch_async(dispatch_get_main_queue()) {
            if distance <= 0.25 {
                self.pickupPinButton.hidden = self.userHoldsPin
            } else {
                self.pickupPinButton.hidden = true
            }
        }
    }
    
    func setupMap(coordinate coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        mapView.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }
    
    // Fetches GPS information for waypoints (city names, distances, etc.)
    func fetchWaypointInformation(waypoints waypoints: Results<LocalWaypoint>) {
        waypointInfoList = []
        
        waypoints.forEach { waypoint in
            
            let location = CLLocation(latitude: waypoint.latitude, longitude: waypoint.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                
                guard error == nil else {
                    print("error getting geocoder information: \(error!)")
                    return
                }
                
                self.waypointInfoList.append(WaypointInfo(waypoint: waypoint, placemark: placemarks?.first))
                
                if self.waypointInfoList.count == waypoints.count {
                    self.displayWaypointInfoList(self.waypointInfoList)
                }
                
            }
        }
    }
    
    func displayWaypointInfoList(waypointInfoList: [WaypointInfo]) {
        previousLocationsStackView.arrangedSubviews.forEach{$0.removeFromSuperview()}
        
        var sortedWaypoints = waypointInfoList.sort{$0.0.waypoint.createdDate.compare($0.1.waypoint.createdDate) == .OrderedAscending}
        
        sortedWaypoints.enumerate().forEach { index, waypointInfo in
            var distanceText: String?
            if index > 0 {
                let previousWaypoint = sortedWaypoints[index-1]
                
                let previousWaypointLocation = CLLocation(latitude: previousWaypoint.waypoint.latitude, longitude: previousWaypoint.waypoint.longitude)
                let currentWaypointLocation = CLLocation(latitude: waypointInfo.waypoint.latitude, longitude: waypointInfo.waypoint.longitude)
                
                let distanceFromPrevious = previousWaypointLocation.distanceFromLocation(currentWaypointLocation)
                
                let formatter = NSNumberFormatter()
                formatter.maximumFractionDigits = 1
                let formattedNumber = formatter.stringFromNumber(distanceFromPrevious * 0.000621371192)
                distanceText = formattedNumber != nil ? "\(formattedNumber!) mi" : nil
            }
            
            let cityLabel = UILabel()
            cityLabel.text = (waypointInfo.cityName ?? "Unknown City") + (distanceText != nil ? " [\(distanceText!)]" : "")
            
            let stackView = UIStackView(arrangedSubviews: [cityLabel])
            stackView.axis = .Vertical
            stackView.alignment = .Leading
            stackView.distribution = .EqualSpacing
            stackView.spacing = 5
            previousLocationsStackView.addArrangedSubview(stackView)
        }
        
    }
    
    func updateUI() {
        titleLabel.text = pinItem.pin.title
        messageView.text = pinItem.pin.message
        
        setupMap(coordinate: CLLocationCoordinate2D(latitude: pinItem.currentWaypoint.latitude, longitude: pinItem.currentWaypoint.longitude))
        
        fetchWaypointInformation(waypoints: pinItem.waypoints)
        
        if userHoldsPin {
            dropPinButton.hidden = false
        } else {
            dropPinButton.hidden = true
        }
    }
    
    @IBAction func pickupPressed(sender: AnyObject) {
        let successHandler: ()->() = {
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupPinButton.hidden = true
                self.dropPinButton.hidden = false
                
                UIView.animateWithDuration(0.8) {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }
                
                let alert = UIAlertController(title: "You picked up \(self.pin.title)!", message: "Take it as far as you can!", preferredStyle: .ActionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        createPickup(successHandler: successHandler)
    }
    
    @IBAction func dropPinPressed(sender: AnyObject) {
        let successHandler: (CLLocation
            , Waypoint)->() = { location, waypoint in
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupPinButton.hidden = false
                self.dropPinButton.hidden = true
                
                UIView.animateWithDuration(0.8) {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }
                
                let alert = UIAlertController(title: "You dropped \(self.pin.title)!", message: "Be sure to check back and see where it goes next!", preferredStyle: .ActionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = location.coordinate
                self.mapView.addAnnotation(newAnnotation)
                
                self.mapView.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
        
        
        if let location = locationHandler.location {
            createWaypoint(location: location, successHandler: successHandler)
            return
        }
        
        locationHandler.executionBlock = { (location, error) in
            
            guard let location = location else {
                print("error getting location: \(error)")
        
                dispatch_async(dispatch_get_main_queue()) {
                    let alert = UIAlertController(title: "Oops", message: "We couldnt find your location!", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                return 
            }
            
            self.createWaypoint(location: location, successHandler: successHandler)
        }
        locationHandler.requestLocation()
        
    }
    
    func createPickup(successHandler successHandler: (()->())) {
        guard let userId = AWSIdentityManager.defaultIdentityManager().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        var pickup = CloudPickup()
        pickup.pinId = pin.id
        pickup.waypointId = pinItem.currentWaypoint.id
        pickup.userId = userId
        pickup.pickupTime = NSDate()
        
        let pinId = pin.id
        let waypointId = pinItem.currentWaypoint.id
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        mapper.save(pickup) { error in
            guard error == nil else {
                print(error)
                return
            }
            
            var pinStatus = CloudPinStatus()
            pinStatus.pinId = pinId
            pinStatus.waypointId = waypointId
            mapper.save(pinStatus) { error in
                guard error == nil else {
                    print(error)
                    mapper.remove(pickup)
                    return
                }
                
                let syncer = Syncer()
                syncer.writeToLocal(LocalPickup.self, cloudRepresentations: [pickup])
                syncer.writeToLocal(LocalPinStatus.self, cloudRepresentations: [pinStatus])
                
                successHandler()
            }
        }
    }
    
    func createWaypoint(location location: CLLocation, successHandler: ((location: CLLocation, waypoint: Waypoint)->())) {
        guard let userId = AWSIdentityManager.defaultIdentityManager().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        var waypoint = CloudWaypoint()
        waypoint.pinId = self.pin.id
        waypoint.dropLocation = location
        waypoint.userId = userId
        waypoint.createdDate = NSDate()
        waypoint.previousWaypointId = self.pinItem.currentWaypoint.id
        
        let pinId = self.pin.id
        let waypointId = waypoint.id
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        mapper.save(waypoint) { error in
            guard error == nil else {
                print(error)
                return
            }
            
            var pinStatus = CloudPinStatus()
            pinStatus.pinId = pinId
            pinStatus.waypointId = waypointId
            mapper.save(pinStatus) { error in
                guard error == nil else {
                    print(error)
                    return
                }
            
                let syncer = Syncer()
                syncer.writeToLocal(LocalWaypoint.self, cloudRepresentations: [waypoint])
                syncer.writeToLocal(LocalPinStatus.self, cloudRepresentations: [pinStatus])
                
                successHandler(location: location, waypoint: waypoint)
            }
        }
    }
    
    @IBAction func backPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
