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

struct MapItem {
    let pin: Pin?
    let pinID: String
    let location: CLLocation
    let annotation: MKPointAnnotation
    
    init(pinID: String, location: CLLocation, pin: Pin? = nil, annotation: MKPointAnnotation) {
        self.pinID = pinID
        self.location = location
        self.pin = pin
        self.annotation = annotation
    }
}

class PinMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, GADBannerViewDelegate {

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
            self.pinInfoView?.location = $0.0
            
            let databaseRef = FIRDatabase.database().reference()
            let droppedPinsRef = databaseRef.child("pins")
                .queryOrdered(byChild: "type")
                .queryEqual(toValue: EventType.Drop.rawValue)
            
            
            let geofire = GeoFire(firebaseRef: databaseRef.child("geofire"))!
            let query = geofire.query(at: $0.0, withRadius: 20.0)
            query?.observe(.keyEntered, with: { key, location in
                self.addMapItem(pinID: key!, location: location!)
            })

        }
        navigationBar.isTranslucent = true
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let buttonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        navigationBar.topItem?.leftBarButtonItem = buttonItem
        
        pinInfoView.pickupSuccessBlock = { pickup, pin, event in
            let title = "You picked up \(pin.title)"
            let message = "You have 24 hours to carry the message wherever you like! Hurry!"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
      
//        adBannerView = createAdBannerView()
    }
    
    func addMapItem(pinID: String, location: CLLocation) {
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

    func createAdBannerView() -> GADBannerView {
        let adView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        adView.adUnitID = "ca-app-pub-0507224597790106/4302627325"
        adView.delegate = self
        adView.rootViewController = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID, "8dba35d6e5470a34c709123c81ec85c1"]
        adView.load(request)
        
        adBannerHolder.addSubview(adView)
        adBannerHolder.isHidden = true
        return adView
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        UIView.animate(withDuration: 0.8, animations: {
            self.adBannerHolder.isHidden = false
        }) 
    }
    
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        UIView.animate(withDuration: 0.8, animations: {
            self.adBannerHolder.isHidden = true
        }) 
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else { return }

    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error updating location: \(error)")
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let id = PinAnnotationView.reuseIdentifier!
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: id)
        
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let selectedMapItem = mapItems.filter {
            if let annotation = view.annotation as? MKPointAnnotation {
                return $0.annotation == annotation
            }
            return false
        }.first
        
        guard let mapItem = selectedMapItem else { return }
        
        guard let pinViewController = self.storyboard?.instantiateViewController(withIdentifier: "PinViewController") as? PinViewController else { return }
    
        pinViewController.pinID = mapItem.pinID
        self.present(pinViewController, animated: true, completion: {
            self.mapView.deselectAnnotation(view.annotation, animated: false)
        })

        return
        
        if !self.view.subviews.contains(pinInfoView) {
            pinInfoView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(pinInfoView)
            
            pinInfoView.peekConstraints = [
                pinInfoView.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -200),
            ]
            
            pinInfoView.showConstraints = [
                pinInfoView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            ]
            
            pinInfoView.hideConstraints = [
                pinInfoView.topAnchor.constraint(equalTo: self.view.bottomAnchor),
            ]
  
            NSLayoutConstraint.activate([
                pinInfoView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
                pinInfoView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
                pinInfoView.heightAnchor.constraint(equalTo: self.view.heightAnchor, constant: -20)
            ] + pinInfoView.hideConstraints)
            
            pinInfoView.layoutIfNeeded()

        }
        pinInfoView.mapItem = mapItem
        
        pinInfoView.titleLabel.text = mapItem.pin?.title
        pinInfoView.messageLabel.text = mapItem.pin?.message
        pinInfoView.peek()
        
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
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
    
    var pickupSuccessBlock: ((_ pickup: Event, _ pin: Pin, _ waypoint: Event)->())!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func closeInfoView(_ sender: AnyObject) {
        hide()
    }
    
    func peek() {
        NSLayoutConstraint.deactivate(self.showConstraints)
        NSLayoutConstraint.deactivate(self.hideConstraints)
        NSLayoutConstraint.activate(self.peekConstraints)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.layoutIfNeeded()
        }, completion: { (finished) in
            self.messageLabel.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }) 
    }
    
    func show() {
        NSLayoutConstraint.deactivate(self.peekConstraints)
        NSLayoutConstraint.deactivate(self.hideConstraints)
        NSLayoutConstraint.activate(self.showConstraints)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.layoutIfNeeded()
        }, completion: { (finished) in
            self.messageLabel.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }) 
    }
    
    func hide() {
        NSLayoutConstraint.deactivate(self.peekConstraints)
        NSLayoutConstraint.deactivate(self.showConstraints)
        NSLayoutConstraint.activate(self.hideConstraints)

        UIView.animate(withDuration: 0.5, animations: {
            self.layoutIfNeeded()
        }, completion: { (finished) in
            self.messageLabel.scrollRangeToVisible(NSRange(location: 0, length: 0))
        }) 
    }
    
    @IBAction func moreInfoPressed(_ sender: UIButton) {
        if offerMoreInfo {
            show()
            infoToggleButton.setTitle("less info", for: UIControlState())
        } else {
            peek()
            infoToggleButton.setTitle("more info", for: UIControlState())
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

    @IBAction func pickUpPinPressed(_ sender: UIButton) {
        // TODO: implement user info
        guard let userID = FIRAuth.auth()?.currentUser?.uid else {
            print("missing user information")
            return
        }
        
        guard let pin = mapItem.pin else {
            print("missing pin")
            return
        }
        
        let databaseRef = FIRDatabase.database().reference()
        let pickupsRef = databaseRef.child("\(pin.id)/pickups")
        
        let pickup = Event(id: pickupsRef.childByAutoId().key,
                        pinID: pin.id,
                     location: location!,
                         type: EventType.Pickup.rawValue,
                       userID: userID,
              previousEventID: pin.currentEvent.id)
        
        
    }
    
    @IBAction func viewDragged(_ sender: UIPanGestureRecognizer) {
        return
        
        let yTranslation = sender.translation(in: self).y
        
        let topViewConstraint = showConstraints[0]
        
        if topViewConstraint.hasExceeded(verticalLimit) {
            totalTranslation += yTranslation
            topViewConstraint.constant = logConstraintValueForYPosition(totalTranslation)
            if sender.state == .ended {
                animateViewBackToLimit()
            }
        } else {
            topViewConstraint.constant += yTranslation
        }
        sender.setTranslation(CGPoint.zero, in: self)
    }
    
    func logConstraintValueForYPosition(_ yPosition : CGFloat) -> CGFloat {
        return verticalLimit * (1 + log10(yPosition/verticalLimit))
    }
    
    func animateViewBackToLimit() {
        let topViewConstraint = showConstraints[0]
        
        topViewConstraint.constant = 0

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 10, options: UIViewAnimationOptions.allowUserInteraction, animations: { () -> Void in
            self.layoutIfNeeded()
            self.totalTranslation = -300
            }, completion: nil)
    }
   
}

private extension NSLayoutConstraint {
    func hasExceeded(_ verticalLimit: CGFloat) -> Bool {
        return self.constant < verticalLimit
    }
}
