//
//  PinViewController.swift
//  Tripple
//
//  Created by Developer on 7/31/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

import Firebase
import FirebaseAuth
import FirebaseDatabase

enum EventType: String {
    case Pickup, Drop
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
    
    var pinID: String! {
        didSet {
            let databaseRef = FIRDatabase.database().reference()
            
            let pinRef = databaseRef.child("pins/\(pinID)")
            pinRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                self.pin = Pin(snapshot: snapshot)
                self.setupPinItem()
                self.updateUI()
            })

            let pinsEventsRef = databaseRef.child("events/\(pinID)")
            pinsEventsRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
                self.events = snapshot.children.map{Event(snapshot: $0 as! FIRDataSnapshot)}
                self.setupPinItem()
                self.updateUI()
            })
        }
    }
    
    private var pin: Pin!
    private var events: [Event]!

    private var pinItem: PinItem!
    
    func setupPinItem() {
        guard let pin = self.pin, let events = self.events else { return }

        pinItem = PinItem(pin: pin, events: events)
    }
    
    var eventInfoList = [EventInfo]()
    
    var userHoldsPin: Bool {
        return pinItem.pin.currentEvent.type == EventType.Pickup.rawValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = true
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = topColor.backgroundColor
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.pickupPinButton.hidden = true
        
        locationHandler.executionBlock = { location, error in
            guard let usersLocation = location else {
                print("error getting location: \(error)")
                return
            }
            self.locationUpdated(location: usersLocation)
        }
        locationHandler.requestLocation()
    }
    
    override func viewDidAppear(animated: Bool) {
        messageView?.scrollRangeToVisible(NSRange(location: 0,length: 0))
    }
    
    func locationUpdated(location location: CLLocation) {
        guard let pinItem = pinItem else { return }
        let pinLocation = pinItem.pin.currentEvent.location
        
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
    
    // Fetches GPS information for events (city names, distances, etc.)
    func fetchEventInformation(events events: [Event]) {
        eventInfoList = []
        
        let descendingEvents = events.sort{$0.0.timestamp.compare($0.1.timestamp) == .OrderedDescending}
        
        let geocoder = CLGeocoder()
        descendingEvents.forEach { event in
            geocoder.reverseGeocodeLocation(event.location) { placemarks, error in
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
    
    func displayEventInfoList(eventInfoList: [EventInfo]) {
        previousLocationsStackView.arrangedSubviews.forEach{$0.removeFromSuperview()}
        
        let sortedEvents = eventInfoList.sort{$0.0.event.timestamp.compare($0.1.event.timestamp) == .OrderedDescending}
        
        sortedEvents.enumerate().forEach { index, eventInfo in
            var distanceText: String?
            if index > 0 {
                let previousEvent = sortedEvents[index-1]
                
                let distanceFromPrevious = previousEvent.event.location.distanceFromLocation(eventInfo.event.location)
                
                let formatter = NSNumberFormatter()
                formatter.maximumFractionDigits = 1
                let formattedNumber = formatter.stringFromNumber(distanceFromPrevious * 0.000621371192)
                distanceText = formattedNumber != nil ? "\(formattedNumber!) mi" : nil
            }
            
            let cityLabel = UILabel()
            cityLabel.text = (eventInfo.cityName ?? "Unknown City") + (distanceText != nil ? " [\(distanceText!)]" : "")
            
            let stackView = UIStackView(arrangedSubviews: [cityLabel])
            stackView.axis = .Vertical
            stackView.alignment = .Leading
            stackView.distribution = .EqualSpacing
            stackView.spacing = 5
            previousLocationsStackView.addArrangedSubview(stackView)
        }
    }
    
    func updateUI() {
        guard let pinItem = pinItem else { return }
        
        titleLabel.text = pinItem.pin.title
        if let message = pinItem.pin.message {
            messageView?.text = message
            messageView?.font = UIFont(name: "Arial", size: 26)
            messageView?.scrollRangeToVisible(NSRange(location: 0,length: 0))
        } else {
            messageView?.removeFromSuperview()
        }
        
        setupMap(coordinate: pinItem.pin.currentEvent.location.coordinate)
        
        fetchEventInformation(events: pinItem.events)
        
        if userHoldsPin {
            dropPinButton.hidden = false
        } else {
            dropPinButton.hidden = true
        }
    }
    
    @IBAction func pickupPressed(sender: AnyObject) {
        let successHandler: (CLLocation
            , Event)->() = { location, event in
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupPinButton.hidden = true
                self.dropPinButton.hidden = false
                
                UIView.animateWithDuration(0.8) {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }
                
                let alert = UIAlertController(title: "You picked up \(self.pinItem.pin.title)!", message: "Take it as far as you can!", preferredStyle: .ActionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        createEvent(type: EventType.Pickup, successHandler: successHandler)
    }
    
    @IBAction func dropPinPressed(sender: AnyObject) {
        let successHandler: (CLLocation
            , Event)->() = { location, event in
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupPinButton.hidden = false
                self.dropPinButton.hidden = true
                
                UIView.animateWithDuration(0.8) {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }
                
                let alert = UIAlertController(title: "You dropped \(self.pinItem.pin.title)!", message: "Be sure to check back and see where it goes next!", preferredStyle: .ActionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = location.coordinate
                self.mapView.addAnnotation(newAnnotation)
                
                self.mapView.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
        
        createEvent(type: EventType.Drop, successHandler: successHandler)
    }
    
    func createEvent(type type: EventType, successHandler: ((location: CLLocation, event: Event)->())) {
        guard let userID = FIRAuth.auth()?.currentUser?.uid else {
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
                    return
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.createEvent(type: type, successHandler: successHandler)
                }
            }
            locationHandler.requestLocation()
            return
        }
        
        let databaseRef = FIRDatabase.database().reference()
        let pinsRef = databaseRef.child("pins")
        let pinRef = pinsRef.child(pinItem.pin.id)
        
        let newEventRef = pinRef.childByAutoId()
        
        let event = Event(id: newEventRef.key, pinID: pinItem.pin.id, location: location, type: type.rawValue, userID: userID, previousEventID: pinItem.pin.currentEvent.id)

        let errorBlock = {
            let actionMessage = event.type == EventType.Drop.rawValue ? "dropping" : "picking up"
            let alert = UIAlertController(title: "Something went wrong", message: "There was an error while \(actionMessage) the pin!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        pinRef.updateChildValues(["currentEvent": event.dictionary])
        newEventRef.setValue(event.dictionary)
        
        successHandler(location: location, event: event)
    }
    
    @IBAction func backPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
