//
//  SecondViewController.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import MapKit
import UIKit

import AWSDynamoDB
import AWSMobileHubHelper
import GoogleMobileAds
import RealmSwift

struct MapItem {
    let pin: Pin
    let currentWaypoint: Waypoint
    let annotation: MKPointAnnotation
    
    init (pin: Pin, waypoint: Waypoint, annotation: MKPointAnnotation) {
        self.pin = pin
        self.currentWaypoint = waypoint
        self.annotation = annotation
    }
}

class PinMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, GADBannerViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var mainStackView: UIStackView!
    
    @IBOutlet weak var adBannerHolder: UIView!
    
    var adBannerView: GADBannerView?
    var adBannerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pinInfoView: PinInfoView!
    
    var realmNotificationToken: NotificationToken?
    
    let locationManager = CLLocationManager()
    
    var mapItems = [MapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.translucent = true
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let buttonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        navigationBar.topItem?.leftBarButtonItem = buttonItem
        
        pinInfoView.pickupSuccessBlock = { pickup, pin, waypoint in
            let title = "You picked up \(pin.title)"
            let message = "You have 24 hours to carry the message wherever you like! Hurry!"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
            alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        realmNotificationToken = try! Realm().addNotificationBlock { notification, realm in
            dispatch_async(dispatch_get_main_queue()) {
                self.updateMap()
            }
        }
        
        updateMap()
    
        adBannerView = createAdBannerView()
    }
    
    func updateMap() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        let realm = try! Realm()

        let pinStatuses: [LocalPin : LocalWaypoint] = realm.objects(LocalPinStatus.self).reduce([:]) { statuses, status in
            let pin = realm.objects(LocalPin.self).filter("_id == %@", status.pinId).first
            let waypoint = realm.objects(LocalWaypoint.self).filter("_id == %@", status.waypointId).first
            
            var dict = statuses
            if let pin = pin, let waypoint = waypoint {
                dict[pin] = waypoint
            }
            return dict
        }
        
        self.mapItems = pinStatuses.map {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: $0.1.latitude, longitude: $0.1.longitude)
            return MapItem(pin: $0.0, waypoint: $0.1, annotation: annotation)
        }
        
        self.mapView.addAnnotations(self.mapItems.map{$0.annotation})
    }
    
    func createAdBannerView() -> GADBannerView {
        let adView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adView.adUnitID = "ca-app-pub-0507224597790106/4302627325"
        adView.delegate = self
        adView.rootViewController = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID, "8dba35d6e5470a34c709123c81ec85c1"]
        adView.loadRequest(request)
        
        adBannerHolder.addSubview(adView)
        adBannerHolder.hidden = true
        return adView
    }
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        UIView.animateWithDuration(0.8) {
            self.adBannerHolder.hidden = false
        }
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        UIView.animateWithDuration(0.8) {
            self.adBannerHolder.hidden = true
        }
    }
    
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
        
        pinInfoView.titleLabel.text = mapItem.pin.title
        pinInfoView.messageLabel.text = mapItem.pin.message
        pinInfoView.peek()
        
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
}

class PinInfoView: UIView {
    
    var mapItem: MapItem!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UITextView!
    
    @IBOutlet weak var infoToggleButton: UIButton!
    
    var offerMoreInfo = true
    
    var peekConstraints = [NSLayoutConstraint]()
    var showConstraints = [NSLayoutConstraint]()
    var hideConstraints = [NSLayoutConstraint]()
    
    let verticalLimit : CGFloat = -10
    var totalTranslation : CGFloat = -200
    
    var pickupSuccessBlock: ((pickup: Pickup, pin: Pin, waypoint: Waypoint)->())!

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
    
    @IBAction func pickUpPinPressed(sender: UIButton) {
        // TODO: implement user info
        guard let userId = AWSIdentityManager.defaultIdentityManager().identityId else {
            print("missing user information")
            return
        }
        
        var pickup = CloudPickup()
        pickup.pinId = mapItem.pin.id
        pickup.waypointId = mapItem.currentWaypoint.id
        pickup.userId = userId
        pickup.pickupTime = NSDate()
        pickup.id = NSUUID().UUIDString
        
        AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper().save(pickup) { error in
            guard error == nil else {
                print("Error creating pickup: \(error!)")
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupSuccessBlock(pickup: pickup, pin: self.mapItem.pin, waypoint: self.mapItem.currentWaypoint)
            }
            
            Syncer().writeToLocal(LocalPickup.self, cloudRepresentations: [pickup])
        }
        
    }
    
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