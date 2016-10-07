//
//  SecondViewController.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

import Firebase
import FirebaseAuth
import FirebaseDatabase
import GeoFire

struct MapItem {
    let pin: Pin?
    let pinID: String
    let location: CLLocation
    let annotation: MKPointAnnotation
    
    init (pinID: String, location: CLLocation, pin: Pin? = nil, annotation: MKPointAnnotation) {
        self.pinID = pinID
        self.location = location
        self.pin = pin
        self.annotation = annotation
    }
}

class PinMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var mainStackView: UIStackView!
    
    @IBOutlet weak var adBannerHolder: UIView!
    
//    var adBannerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pinInfoView: PinInfoView!
        
    let locationManager = CLLocationManager()
    
    let locationHandler = LocationHandler()
    
    var mapItems = [MapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationHandler.executionBlock = {
            self.pinInfoView?.location = $0.location
            
            
            let databaseRef = FIRDatabase.database().reference()
            let droppedPinsRef = databaseRef.child("pins")
                .queryOrderedByChild("type")
                .queryEqualToValue(EventType.Drop.rawValue)
            
            let geofire = GeoFire(firebaseRef: databaseRef.child("geofire"))
            
            let query = geofire.queryAtLocation($0.location, withRadius: 20.0)
            query.observeEventType(.KeyEntered, withBlock: { key, location in
                self.addMapItem(pinID: key, location: location)
            })

        }
        locationHandler.requestLocation()
        
        navigationBar.translucent = true
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let buttonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        navigationBar.topItem?.leftBarButtonItem = buttonItem
        
        pinInfoView.pickupSuccessBlock = { pin, event in
            let title = "You picked up \(pin.title)"
            let message = "You have 24 hours to carry the message wherever you like! Hurry!"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
            alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
      
//        adBannerView = createAdBannerView()
    }
    
    func addMapItem(pinID pinID: String, location: CLLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
    
        let newMapItem = MapItem(pinID: pinID, location: location, annotation: annotation)
        
        self.mapItems.append(newMapItem)
        
        self.mapView.addAnnotation(newMapItem.annotation)
    }

//    func createAdBannerView() -> GADBannerView {
//        let adView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
//        adView.adUnitID = "ca-app-pub-0507224597790106/4302627325"
//        adView.delegate = self
//        adView.rootViewController = self
//        let request = GADRequest()
//        request.testDevices = [kGADSimulatorID, "8dba35d6e5470a34c709123c81ec85c1"]
//        adView.loadRequest(request)
//        
//        adBannerHolder.addSubview(adView)
//        adBannerHolder.hidden = true
//        return adView
//    }
//    
//    func adViewDidReceiveAd(bannerView: GADBannerView!) {
//        UIView.animateWithDuration(0.8) {
//            self.adBannerHolder.hidden = false
//        }
//    }
//    
//    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
//        UIView.animateWithDuration(0.8) {
//            self.adBannerHolder.hidden = true
//        }
//    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else { return }

    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error updating location: \(error)")
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {

        let id = PinAnnotationView.reuseIdentifier!
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(id)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            annotationView!.image = UIImage(named: "mapPin")
            annotationView!.canShowCallout = false
        } else {
            //we are re-using a view, update its annotation reference...
            annotationView!.annotation = annotation
        }
        
        annotationView?.detailCalloutAccessoryView = nil
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let selectedMapItem = mapItems.filter {
            if let annotation = view.annotation as? MKPointAnnotation {
                return $0.annotation == annotation
            }
            return false
        }.first
        
        guard let mapItem = selectedMapItem else { return }
        
        guard let pinViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PinViewController") as? PinViewController else { return }
    
        pinViewController.pinID = mapItem.pinID
        self.presentViewController(pinViewController, animated: true, completion: {
            self.mapView.deselectAnnotation(view.annotation, animated: false)
        })

        return
        
        if !self.view.subviews.contains(pinInfoView) {
            pinInfoView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(pinInfoView)
            
            pinInfoView.peekConstraints = [
                pinInfoView.topAnchor.constraintEqualToAnchor(self.view.bottomAnchor, constant: -200),
            ]
            
            pinInfoView.showConstraints = [
                pinInfoView.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor),
            ]
            
            pinInfoView.hideConstraints = [
                pinInfoView.topAnchor.constraintEqualToAnchor(self.view.bottomAnchor),
            ]
  
            NSLayoutConstraint.activateConstraints([
                pinInfoView.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor, constant: 0),
                pinInfoView.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor, constant: 0),
                pinInfoView.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor, constant: -20)
            ] + pinInfoView.hideConstraints)
            
            pinInfoView.layoutIfNeeded()

        }
        pinInfoView.mapItem = mapItem
        
        pinInfoView.titleLabel.text = mapItem.pin?.title
        pinInfoView.messageLabel.text = mapItem.pin?.message
        pinInfoView.peek()
        
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        let targetGeohash = Geohash.encode(coordinate: mapView.centerCoordinate, 6)
        let targetGeohash = ""
//        updateCache(geohashes: Geohash.neighbors(targetGeohash))
    }
    
}

class PinInfoView: UIView {
    
    var mapItem: MapItem!
    
    var location: CLLocation?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UITextView!
    
    @IBOutlet weak var infoToggleButton: UIButton!
    
    var offerMoreInfo = true
    
    var peekConstraints = [NSLayoutConstraint]()
    var showConstraints = [NSLayoutConstraint]()
    var hideConstraints = [NSLayoutConstraint]()
    
    let verticalLimit : CGFloat = -10
    var totalTranslation : CGFloat = -200
    
    var pickupSuccessBlock: ((pin: Pin, event: Event)->())!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func closeInfoView(sender: AnyObject) {
        hide()
    }
    
    func peek() {
        NSLayoutConstraint.deactivateConstraints(self.showConstraints)
        NSLayoutConstraint.deactivateConstraints(self.hideConstraints)
        NSLayoutConstraint.activateConstraints(self.peekConstraints)
        
        UIView.animateWithDuration(0.5, animations: {
            self.layoutIfNeeded()
        }) { (finished) in
            self.messageLabel.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
    }
    
    func show() {
        NSLayoutConstraint.deactivateConstraints(self.peekConstraints)
        NSLayoutConstraint.deactivateConstraints(self.hideConstraints)
        NSLayoutConstraint.activateConstraints(self.showConstraints)
        
        UIView.animateWithDuration(0.5, animations: {
            self.layoutIfNeeded()
        }) { (finished) in
            self.messageLabel.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
    }
    
    func hide() {
        NSLayoutConstraint.deactivateConstraints(self.peekConstraints)
        NSLayoutConstraint.deactivateConstraints(self.showConstraints)
        NSLayoutConstraint.activateConstraints(self.hideConstraints)

        UIView.animateWithDuration(0.5, animations: {
            self.layoutIfNeeded()
        }) { (finished) in
            self.messageLabel.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }
    }
    
    @IBAction func moreInfoPressed(sender: UIButton) {
        if offerMoreInfo {
            show()
            infoToggleButton.setTitle("less info", forState: .Normal)
        } else {
            peek()
            infoToggleButton.setTitle("more info", forState: .Normal)
        }
        
        offerMoreInfo = !offerMoreInfo
    }
    
//    @IBAction func pickUpPinPressed(sender: UIButton) {
//        // TODO: implement user info
//        guard let userID = FIRAuth.auth()?.currentUser?.uid else {
//            print("missing user information")
//            return
//        }
//        
//        guard let location = location else {
//            print("missing location information")
//            return
//        }
//        
//        var pickup = Event(pinID: mapItem.pin.id, location: location, type: EventType.Pickup.rawValue, userID: userID)
//        
//       
//
//        let databaseRef = FIRDatabase.database().reference()
//        let newEventRef = databaseRef.child("events/\(mapItem.pin.id)")
//        newEventRef.setValue(pickup)
//
//
//            guard error == nil else {
//                print("Error creating pickup: \(error!)")
//                return
//            }
//            
//            dispatch_async(dispatch_get_main_queue()) {
//                self.pickupSuccessBlock(pin: self.mapItem.pin, event: pickup)
//            }
//            
//        }
//        
//    }
    
    @IBAction func viewDragged(sender: UIPanGestureRecognizer) {
        return
        
        let yTranslation = sender.translationInView(self).y
        
        let topViewConstraint = showConstraints[0]
        
        if topViewConstraint.hasExceeded(verticalLimit) {
            totalTranslation += yTranslation
            topViewConstraint.constant = logConstraintValueForYPosition(totalTranslation)
            if sender.state == .Ended {
                animateViewBackToLimit()
            }
        } else {
            topViewConstraint.constant += yTranslation
        }
        sender.setTranslation(CGPointZero, inView: self)
    }
    
    func logConstraintValueForYPosition(yPosition : CGFloat) -> CGFloat {
        return verticalLimit * (1 + log10(yPosition/verticalLimit))
    }
    
    func animateViewBackToLimit() {
        let topViewConstraint = showConstraints[0]
        
        topViewConstraint.constant = 0

        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 10, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
            self.layoutIfNeeded()
            self.totalTranslation = -300
            }, completion: nil)
    }
   
}

private extension NSLayoutConstraint {
    func hasExceeded(verticalLimit: CGFloat) -> Bool {
        return self.constant < verticalLimit
    }
}