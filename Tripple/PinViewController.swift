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
            pinRef.observeSingleEvent(of: .value, with: { snapshot in
                self.pin = Pin(snapshot: snapshot)
                self.setupPinItem()
                self.updateUI()
            })

            let pinsEventsRef = databaseRef.child("events/\(pinID)")
            pinsEventsRef.observeSingleEvent(of: .value, with: { snapshot in
                self.events = snapshot.children.map{Event(snapshot: $0 as! FIRDataSnapshot)}
                self.setupPinItem()
                self.updateUI()
            })
        }
    }
    
    fileprivate var pin: Pin!
    fileprivate var events: [Event]!

    fileprivate var pinItem: PinItem!
    
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
        
        navigationBar.isTranslucent = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = topColor.backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.pickupPinButton.isHidden = true
        
        locationHandler.executionBlock = { location, error in
            guard let usersLocation = location else {
                print("error getting location: \(error)")
                return
            }
            self.locationUpdated(location: usersLocation)
        }
        locationHandler.requestLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        messageView?.scrollRangeToVisible(NSRange(location: 0,length: 0))
    }
    
    func locationUpdated(location: CLLocation) {
        guard let pinItem = pinItem else { return }
        let pinLocation = pinItem.pin.currentEvent.location
        
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
    
    // Fetches GPS information for events (city names, distances, etc.)
    func fetchEventInformation(events: [Event]) {
        eventInfoList = []
        
        let descendingEvents = events.sorted{$0.0.createdDate.compare($0.1.createdDate as Date) == .orderedDescending}
        
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
    
    func displayEventInfoList(_ eventInfoList: [EventInfo]) {
        previousLocationsStackView.arrangedSubviews.forEach{$0.removeFromSuperview()}
        
        let sortedEvents = eventInfoList.sorted{$0.0.event.createdDate.compare($0.1.event.createdDate as Date) == .orderedDescending}
        
        sortedEvents.enumerated().forEach { index, eventInfo in
            var distanceText: String?
            if index > 0 {
                let previousEvent = sortedEvents[index-1]
                
                let distanceFromPrevious = previousEvent.event.location.distance(from: eventInfo.event.location)
                
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 1
                let formattedNumber = formatter.string(from: NSNumber(value: distanceFromPrevious * 0.000621371192))
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
            dropPinButton.isHidden = false
        } else {
            dropPinButton.isHidden = true
        }
    }
    
    @IBAction func pickupPressed(_ sender: AnyObject) {
        let successHandler: (CLLocation
            , Event)->() = { location, event in
            DispatchQueue.main.async {
                self.pickupPinButton.isHidden = true
                self.dropPinButton.isHidden = false
                
                UIView.animate(withDuration: 0.8, animations: {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }) 
                
                let alert = UIAlertController(title: "You picked up \(self.pinItem.pin.title)!", message: "Take it as far as you can!", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        createEvent(type: EventType.Pickup, successHandler: successHandler)
    }
    
    @IBAction func dropPinPressed(_ sender: AnyObject) {
        let successHandler: (CLLocation
            , Event)->() = { location, event in
            DispatchQueue.main.async {
                self.pickupPinButton.isHidden = false
                self.dropPinButton.isHidden = true
                
                UIView.animate(withDuration: 0.8, animations: {
                    self.pickupPinButton.layoutIfNeeded()
                    self.dropPinButton.layoutIfNeeded()
                }) 
                
                let alert = UIAlertController(title: "You dropped \(self.pinItem.pin.title)!", message: "Be sure to check back and see where it goes next!", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                let newAnnotation = MKPointAnnotation()
                newAnnotation.coordinate = location.coordinate
                self.mapView.addAnnotation(newAnnotation)
                
                self.mapView.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        }
        
        createEvent(type: EventType.Drop, successHandler: successHandler)
    }
    
    func createEvent(type: EventType, successHandler: @escaping ((_ location: CLLocation, _ event: Event)->())) {
        guard let userID = FIRAuth.auth()?.currentUser?.uid else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        guard let location = locationHandler.location else {
            locationHandler.executionBlock = { location, error in
                
                guard location != nil else {
                    print("error getting location: \(error)")
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Oops", message: "We couldnt find your location!", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                DispatchQueue.main.async {
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
            let alert = UIAlertController(title: "Something went wrong", message: "There was an error while \(actionMessage) the pin!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        pinRef.updateChildValues(["currentEvent": event.dictionary])
        newEventRef.setValue(event.dictionary)
        
        successHandler(location, event)
    }
    
    @IBAction func backPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}
