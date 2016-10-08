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
import GeohashKitiOS
import GoogleMobileAds
import RealmSwift

struct MapItem {
    let pin: Pin
    let currentEvent: Event
    let annotation: MKPointAnnotation
    
    init (pin: Pin, event: Event, annotation: MKPointAnnotation) {
        self.pin = pin
        self.currentEvent = event
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
    
    let locationHandler = LocationHandler()
    
    var mapItems = [MapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationHandler.executionBlock = {
            self.pinInfoView?.location = $0.location
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
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "okay", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        realmNotificationToken = try! Realm().addNotificationBlock { notification, realm in
            DispatchQueue.main.async {
                self.updateMap()
            }
        }
        
        updateMap()
    
        adBannerView = createAdBannerView()
        
        if CacheTransaction.cacheHasExpired(cacheType: .PublicPins) {
            // if no caches were performed within the expiration interval, update the cache
            
            updateCache()
        }
    }
    
    func updateCache(geohashes geohashes: [String]? = nil) {
        var sortKeyComparisons: String?
        if let neighbors = geohashes {
            sortKeyComparisons = neighbors.enumerate().reduce(" AND (", combine: { (construction, enumeration) -> String in
                let index = enumeration.index
                let neighbor = enumeration.element
                
                var newString = construction + "begins_with (geohash, neighbor)"
                if index < neighbors.count - 1 {
                    newString += " OR "
                }
                
                return newString
                
            })
            sortKeyComparisons! += ")"
        }
        
        
        let expression = AWSDynamoDBQueryExpression()
//        expression.limit = geohashes == nil ? 50 : nil
        expression.indexName = "Status-Geohash-Index"
        expression.keyConditionExpression = "(pinStatus = :status)" + (sortKeyComparisons ?? "")
        expression.expressionAttributeValues = [
            ":status": EventType.Drop.rawValue,
        ]
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        mapper.query(CloudPin.self, expression: expression) { response, error in
            
            
            
            // need to get pins for multiple grid spaces around the center of the map, user batch queries to get pins for all grids
            
            
            
            
            
            
            
            
            
            
            guard let response = response else {
                print("no response: \(error)")
                return
            }
            
            guard let pins = response.items as? [CloudPin] else {
                return
            }
            
            var eventQueryInfo = [String: String]()
            pins.enumerate().forEach {
                eventQueryInfo[":id\($0.index)"] = $0.element.id
            }
            
            let eventExpression = AWSDynamoDBScanExpression()
            eventExpression.filterExpression = "#pinId IN (\(eventQueryInfo.keys.joinWithSeparator(",")))"
            eventExpression.expressionAttributeNames = ["#pinId": "pinId",]
            eventExpression.expressionAttributeValues = eventQueryInfo
            mapper.scan(CloudEvent.self, expression: eventExpression) { response, error in
                
                guard let response = response else {
                    print("no response: \(error)")
                    return
                }
                
                guard let events = response.items as? [CloudEvent] else {
                    return
                }
                
                let syncer = Syncer()
                syncer.writeToLocal(LocalPin.self, cloudRepresentations: pins)
                syncer.writeToLocal(LocalEvent.self, cloudRepresentations: events)
                CacheTransaction.markCacheUpdated(cacheType: .PublicPins)
            }
        }
    }
    
    func updateMap() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        let realm = try! Realm()
        let pins = realm.objects(LocalPin)

        let pinItems = pins.map(PinItem.init).filter{$0.pin.currentEvent != nil}
        
        self.mapItems = pinItems.map {
            let event = $0.pin.currentEvent!
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: event.latitude, longitude: event.longitude)
            return MapItem(pin: $0.pin, event: event, annotation: annotation)
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
        
        guard let pinViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PinViewController") as? PinViewController else { return }
        
        pinViewController.pinId = mapItem.pin.id
        
        self.presentViewController(pinViewController, animated: true, completion: nil)
    
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
        
        pinInfoView.titleLabel.text = mapItem.pin.title
        pinInfoView.messageLabel.text = mapItem.pin.message
        pinInfoView.peek()
        
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let targetGeohash = Geohash.encode(coordinate: mapView.centerCoordinate, 6)
        
//        updateCache(geohashes: Geohash.neighbors(targetGeohash))
        updateCache()
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
    
    @IBAction func pickUpPinPressed(_ sender: UIButton) {
        // TODO: implement user info
        guard let userId = AWSIdentityManager.default().identityId else {
            print("missing user information")
            return
        }
        
        guard let location = location else {
            print("missing location information")
            return
        }
        
        var pickup = CloudEvent()
        pickup.pinId = mapItem.pin.id
        pickup.userId = userId
        pickup.pickupTime = Date()
        pickup.id = UUID().uuidString
        
        AWSDynamoDBObjectMapper.default().save(pickup) { error in
            guard error == nil else {
                print("Error creating pickup: \(error!)")
                return
            }
            
            DispatchQueue.main.async {
                self.pickupSuccessBlock(pickup: pickup, pin: self.mapItem.pin, waypoint: self.mapItem.currentWaypoint)
            }
            
            Syncer().writeToLocal(LocalEvent.self, cloudRepresentations: [pickup])
        }
        
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
