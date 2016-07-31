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

class ViewPinController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var pinInfoView: PinInfoView!
    
    let locationManager = CLLocationManager()
    
    var mapItems = [MapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let buttonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        navigationBar.topItem?.leftBarButtonItem = buttonItem
        
        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationBar.shadowImage = UIImage()
        
        // set translucent to make clear
        navigationBar.translucent = false
        
        pinInfoView.pickupSuccessBlock = { pickup, pin, waypoint in
            let title = pin._title != nil ? "You picked up \(pin._title!)" : "You picked up a pin!"
            let message = "You have 24 hours to carry the message wherever you like! Hurry!"
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
            alert.addAction(UIAlertAction(title: "okay", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 5
        
        objectMapper.scan(Pin.self, expression: scanExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            
            guard let response = response else {
                print("no response")
                return
            }
            
            guard let pins = response.items as? [Pin] else {
                return
            }
            
            let pinIds = pins.map{$0._id!}
            
            let idList = pinIds.joinWithSeparator(",")
            
            var dict = [String: String]()
            pinIds.enumerate().forEach {
                dict[":pinId\($0.index)"] = $0.element
            }
            
            let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            let scanExpression = AWSDynamoDBScanExpression()
            scanExpression.filterExpression = "#pinId IN (\(dict.keys.joinWithSeparator(",")))"
            scanExpression.expressionAttributeNames = ["#pinId": "pinId",]
            scanExpression.expressionAttributeValues = dict
            
            objectMapper.scan(Waypoint.self, expression: scanExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    
                    guard let response = response else {
                        print("no response")
                        return
                    }
                    
                    guard let waypoints = response.items as? [Waypoint] else {
                        return
                    }
                    
                    var pinStatuses = [Pin: Waypoint]()
                    
                    pins.forEach { pin in
                        if let currentWaypoint = (waypoints.filter{$0._pinId == pin._id}).first {
                            pinStatuses[pin] = currentWaypoint
                        }
                    }
                    
                    self.mapItems = pinStatuses.filter{$0.1._location != nil}.map {
                        let annotation = MKPointAnnotation()
                        annotation.title = "Pin"
                        annotation.coordinate = $0.1.dropLocation!.coordinate
                        return MapItem(pin: $0.0, waypoint: $0.1, annotation: annotation)
                    }
                    
                    print("number of items: \(pinStatuses.count)")
                    
                    self.mapView.addAnnotations(self.mapItems.map{$0.annotation})
                    
                })
            })
        })
        
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
        let selectedAnnotation = mapItems.filter {
            if let annotation = view.annotation as? MKPointAnnotation {
                return $0.annotation == annotation
            }
            return false
        }.first
        
        guard let mapItem = selectedAnnotation else { return }
        
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
        
        pinInfoView.titleLabel.text = mapItem.pin._title
        pinInfoView.messageLabel.text = mapItem.pin._message
        pinInfoView.peek()
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
        guard let userId = "shibby" as String? else {
            print("missing user information")
            return
        }
        
        let pickup = Pickup(pin: mapItem.pin, waypoint: mapItem.currentWaypoint, userId: userId)
        
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        objectMapper.save(pickup) { error in
            guard error == nil else {
                print("Error creating pickup: \(error!)")
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.pickupSuccessBlock(pickup: pickup, pin: self.mapItem.pin, waypoint: self.mapItem.currentWaypoint)
            }
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