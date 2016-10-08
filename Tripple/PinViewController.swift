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

<<<<<<< HEAD
=======
struct PinItem {
    let pin: Pin
    let waypoints: Results<LocalWaypoint>
    
    var currentWaypoint: Waypoint {
        return waypoints.sorted{$0.0.createdDate.compare($0.1.createdDate) == .orderedDescending}[0]
    }
    
    init(pin: Pin, waypoints: Results<LocalWaypoint>) {
        self.pin = pin
        self.waypoints = waypoints
    }
}

>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
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
    
    struct EventInfo {
        let event: Event
        var placemark: CLPlacemark?
        
        init(event: Event, placemark: CLPlacemark?) {
            self.event = event
            self.placemark = placemark
        }
        
        var cityName: String? {
            return placemark?.addressDictionary?["City"] as? String
        }
    }
    
    var pinId = "" {
        didSet {
            
            guard let pin = try! Realm().objectForPrimaryKey(LocalPin.self, key: pinId) else {
                return
            }
            pinItem = PinItem(pin: pin)
        }
    }
    
    var pinItem: PinItem!
    
    var eventInfoList = [EventInfo]()
    
    var userHoldsPin: Bool {
        return pinItem.pin.currentEvent?.type == EventType.Pickup.rawValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        realmNotificationToken = try! Realm().addNotificationBlock { notification, realm in
            DispatchQueue.main.async {
                self.updateUI()
            }
        }
        
        navigationBar.isTranslucent = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = topColor.backgroundColor
        
        guard CacheTransaction.cacheHasExpired(cacheType: .PinEvents, note: pinId) else {
            return
        }
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let query = AWSDynamoDBQueryExpression()
        query.indexName = "Pin-Timestamp-Index"
        query.keyConditionExpression = "pinId = :id"
        query.expressionAttributeValues = [":id": "[us-east-1:9380f898-c0d5-45f4-a3d9-ce126b8e078b]1470980661"]
        mapper.query(CloudEvent.self, expression: query) { response, error in
            guard error == nil else {
                print("error: \(error)")
                return
            }
            
            guard let events = response?.items as? [CloudEvent] else { return }
            
            Syncer().writeToLocal(LocalEvent.self, cloudRepresentations: events) {
                CacheTransaction.markCacheUpdated(cacheType: .PinEvents, note: self.pinId, realm: $0)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.pickupPinButton.isHidden = true

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
    
<<<<<<< HEAD
    override func viewDidAppear(animated: Bool) {
        messageView?.scrollRangeToVisible(NSRange(location: 0,length: 0))
    }
    
    func locationUpdated(location location: CLLocation) {
        guard let currentEvent = pinItem.pin.currentEvent else {
            return
        }
        
        let pinLocation = CLLocation(latitude: currentEvent.latitude, longitude: currentEvent.longitude)
=======
    func locationUpdated(location: CLLocation) {
        let pinLocation = CLLocation(latitude: self.pinItem.currentWaypoint.latitude, longitude: self.pinItem.currentWaypoint.longitude)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        
        let distance = location.distance(from: pinLocation) * 0.000621371 // in miles
        DispatchQueue.main.async {
            if distance <= 0.25 {
                self.pickupPinButton.isHidden = self.userHoldsPin
            } else {
                self.pickupPinButton.isHidden = true
            }
        }
    }
    
    func setupMap(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        mapView.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }
    
<<<<<<< HEAD
    // Fetches GPS information for events (city names, distances, etc.)
    func fetchEventInformation(events events: Results<LocalEvent>) {
        eventInfoList = []
=======
    // Fetches GPS information for waypoints (city names, distances, etc.)
    func fetchWaypointInformation(waypoints: Results<LocalWaypoint>) {
        waypointInfoList = []
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        
        events.sorted("_timestamp", ascending: false).forEach { event in
            
            let location = CLLocation(latitude: event.latitude, longitude: event.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                
                guard error == nil else {
                    print("error getting geocoder information: \(error!)")
                    return
                }
                
                self.eventInfoList.append(EventInfo(event: event, placemark: placemarks?.first))
                
                if self.eventInfoList.count == events.count {
                    self.displayEventInfoList(self.eventInfoList)
                }
            }
        }
    }
    
<<<<<<< HEAD
    func displayEventInfoList(eventInfoList: [EventInfo]) {
        previousLocationsStackView.arrangedSubviews.forEach{$0.removeFromSuperview()}
        
        var sortedEvents = eventInfoList.sort{$0.0.event.createdDate.compare($0.1.event.createdDate) == .OrderedDescending}
        
        sortedEvents.enumerate().forEach { index, eventInfo in
=======
    func displayWaypointInfoList(_ waypointInfoList: [WaypointInfo]) {
        previousLocationsStackView.arrangedSubviews.forEach{$0.removeFromSuperview()}
        
        var sortedWaypoints = waypointInfoList.sorted{$0.0.waypoint.createdDate.compare($0.1.waypoint.createdDate as Date) == .orderedAscending}
        
        sortedWaypoints.enumerated().forEach { index, waypointInfo in
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
            var distanceText: String?
            if index > 0 {
                let previousEvent = sortedEvents[index-1]
                
                let previousEventLocation = CLLocation(latitude: previousEvent.event.latitude, longitude: previousEvent.event.longitude)
                let currentEventLocation = CLLocation(latitude: eventInfo.event.latitude, longitude: eventInfo.event.longitude)
                
<<<<<<< HEAD
                let distanceFromPrevious = previousEventLocation.distanceFromLocation(currentEventLocation)
=======
                let distanceFromPrevious = previousWaypointLocation.distance(from: currentWaypointLocation)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
                
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                let formattedNumber = formatter.string(from: distanceFromPrevious * 0.000621371192)
                distanceText = formattedNumber != nil ? "\(formattedNumber!) mi" : nil
            }
            
            let cityLabel = UILabel()
            cityLabel.text = (eventInfo.cityName ?? "Unknown City") + (distanceText != nil ? " [\(distanceText!)]" : "")
            
            let stackView = UIStackView(arrangedSubviews: [cityLabel])
            stackView.axis = .vertical
            stackView.alignment = .leading
            stackView.distribution = .equalSpacing
            stackView.spacing = 5
            previousLocationsStackView.addArrangedSubview(stackView)
        }
        
    }
    
    func updateUI() {
        titleLabel.text = pinItem.pin.title
        if let message = pinItem.pin.message {
            messageView?.text = message
            messageView?.font = UIFont(name: "Arial", size: 26)
            messageView?.scrollRangeToVisible(NSRange(location: 0,length: 0))
        } else {
            messageView?.removeFromSuperview()
        }
        
        guard let event = pinItem.pin.currentEvent else {
            print("error: missing event")
            return
        }
        
        setupMap(coordinate: CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude))
        
        fetchEventInformation(events: pinItem.pin.events)
        
        if userHoldsPin {
            dropPinButton.isHidden = false
        } else {
            dropPinButton.isHidden = true
        }
    }
    
<<<<<<< HEAD
    @IBAction func pickupPressed(sender: AnyObject) {
        let successHandler: (CLLocation
            , Event)->() = { location, event in
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupPinButton.hidden = true
                self.dropPinButton.hidden = false
=======
    @IBAction func pickupPressed(_ sender: AnyObject) {
        let successHandler: ()->() = {
            DispatchQueue.main.async {
                self.pickupPinButton.isHidden = true
                self.dropPinButton.isHidden = false
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
                
                UIView.animate(withDuration: 0.8, animations: {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }) 
                
<<<<<<< HEAD
                let alert = UIAlertController(title: "You picked up \(self.pinItem.pin.title)!", message: "Take it as far as you can!", preferredStyle: .ActionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
=======
                let alert = UIAlertController(title: "You picked up \(self.pin.title)!", message: "Take it as far as you can!", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
            }
        }
        
        createEvent(type: EventType.Pickup, successHandler: successHandler)
    }
    
    @IBAction func dropPinPressed(_ sender: AnyObject) {
        let successHandler: (CLLocation
<<<<<<< HEAD
            , Event)->() = { location, event in
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupPinButton.hidden = false
                self.dropPinButton.hidden = true
=======
            , Waypoint)->() = { location, waypoint in
            DispatchQueue.main.async {
                self.pickupPinButton.isHidden = false
                self.dropPinButton.isHidden = true
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
                
                UIView.animate(withDuration: 0.8, animations: {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }) 
                
<<<<<<< HEAD
                let alert = UIAlertController(title: "You dropped \(self.pinItem.pin.title)!", message: "Be sure to check back and see where it goes next!", preferredStyle: .ActionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
=======
                let alert = UIAlertController(title: "You dropped \(self.pin.title)!", message: "Be sure to check back and see where it goes next!", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = location.coordinate
                self.mapView.addAnnotation(newAnnotation)
                
                self.mapView.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
        
<<<<<<< HEAD
        createEvent(type: EventType.Drop, successHandler: successHandler)
    }
    
    func createEvent(type type: EventType, successHandler: ((location: CLLocation, event: Event)->())) {
        guard let userId = AWSIdentityManager.defaultIdentityManager().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        guard let location = locationHandler.location else {
            locationHandler.executionBlock = { location, error in
                
                guard location != nil else {
                    print("error getting location: \(error)")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        let alert = UIAlertController(title: "Oops", message: "We couldnt find your location!", preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
=======
        
        if let location = locationHandler.location {
            createWaypoint(location: location, successHandler: successHandler)
            return
        }
        
        locationHandler.executionBlock = { (location, error) in
            
            guard let location = location else {
                print("error getting location: \(error)")
        
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Oops", message: "We couldnt find your location!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return 
            }
            
            self.createWaypoint(location: location, successHandler: successHandler)
        }
        locationHandler.requestLocation()
        
    }
    
    func createPickup(successHandler: @escaping (()->())) {
        guard let userId = AWSIdentityManager.default().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        var pickup = CloudPickup()
        pickup.pinId = pin.id
        pickup.waypointId = pinItem.currentWaypoint.id
        pickup.userId = userId
        pickup.pickupTime = Date()
        
        let pinId = pin.id
        let waypointId = pinItem.currentWaypoint.id
        
        let mapper = AWSDynamoDBObjectMapper.default()
        mapper.save(pickup) { error in
            guard error == nil else {
                print(error)
                return
            }
            
            var pinStatus = CloudPinStatus()
            pinStatus?.pinId = pinId
            pinStatus?.waypointId = waypointId
            mapper.save(pinStatus!) { error in
                guard error == nil else {
                    print(error)
                    mapper.remove(pickup)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
                    return
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.createEvent(type: type, successHandler: successHandler)
                }
            }
<<<<<<< HEAD
            locationHandler.requestLocation()
            return
        }
        
        guard let latestEvent = pinItem.pin.currentEvent else { return }
=======
        }
    }
    
    func createWaypoint(location: CLLocation, successHandler: @escaping ((_ location: CLLocation, _ waypoint: Waypoint)->())) {
        guard let userId = AWSIdentityManager.default().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        var waypoint = CloudWaypoint()
        waypoint.pinId = self.pin.id
        waypoint.dropLocation = location
        waypoint.userId = userId
        waypoint.createdDate = Date()
        waypoint.previousWaypointId = self.pinItem.currentWaypoint.id
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        
        var event = CloudEvent()
        event.userId = userId
        event.createdDate = NSDate()
        event.pinId = pinItem.pin.id
        event.location = location
        event.type = type.rawValue
        event.previousEventId = latestEvent.id

        let pinId = pinItem.pin.id
        
<<<<<<< HEAD
        let updatePin = AWSDynamoDBUpdateItemInput()
        updatePin.tableName = CloudPin.dynamoDBTableName()
        let hashValue = AWSDynamoDBAttributeValue()
        hashValue.S = pinItem.pin.userId
        let rangeValue = AWSDynamoDBAttributeValue()
        rangeValue.N = "\(Int(pinItem.pin.createdDate.timeIntervalSince1970))"
        let oldEventIdValue = AWSDynamoDBAttributeValue()
        oldEventIdValue.S = latestEvent.id

        let idValue = AWSDynamoDBAttributeValue()
        idValue.S = event.id

        let newEventValue = AWSDynamoDBAttributeValue()
        newEventValue.M = [
            "id": idValue,
        ]
        let statusValue = AWSDynamoDBAttributeValue()
        statusValue.S = event.type
        let geohashValue = AWSDynamoDBAttributeValue()
        geohashValue.S = event.geohash
        
        updatePin.key = ["userId": hashValue, "timestamp": rangeValue]
        
        updatePin.conditionExpression = "currentEvent.id = :oldEventId"
        updatePin.updateExpression = "SET currentEvent = :newEvent, pinStatus = :status, geohash = :geohash"
        updatePin.expressionAttributeValues = [
            ":oldEventId": oldEventIdValue,
            ":newEvent": newEventValue,
            ":status": statusValue,
            ":geohash": geohashValue,
        ]
        
        let errorBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                let actionMessage = event.type == EventType.Drop.rawValue ? "dropping" : "picking up"
                let alert = UIAlertController(title: "Something went wrong", message: "There was an error while \(actionMessage) the pin!", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        AWSDynamoDB.defaultDynamoDB().updateItem(updatePin) { response, error in
=======
        let mapper = AWSDynamoDBObjectMapper.default()
        mapper.save(waypoint) { error in
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
            guard error == nil else {
                print("Error updating pin: \(error!)")
                errorBlock()
                return
            }
            
<<<<<<< HEAD
            AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(event) { error in
=======
            var pinStatus = CloudPinStatus()
            pinStatus?.pinId = pinId
            pinStatus?.waypointId = waypointId
            mapper.save(pinStatus!) { error in
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
                guard error == nil else {
                    print("Error creating event: \(error!)")
                    errorBlock()
                    return
                }
                
<<<<<<< HEAD
                let syncer = Syncer()
                syncer.updateLocal(LocalPin.self, primaryKey: pinId, updateBlock: {
                    var pin = $0
                    pin.pinStatus = event.type
                    pin.geohash = event.geohash
                })
                syncer.writeToLocal(LocalEvent.self, cloudRepresentations: [event])

                successHandler(location: location, event: event)
=======
                successHandler(location, waypoint)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
            }
        }
    }
    
    @IBAction func backPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}
