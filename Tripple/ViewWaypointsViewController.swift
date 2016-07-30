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
        
        let pin = Pin()
        pin._title = "BLM"
        pin._message = "Jonah made this."
        
        
        let firstWaypoint = Waypoint(pin: pin, location: CLLocation(latitude: 10, longitude: 10))
        let secondWaypoint = Waypoint(pin: pin, location: CLLocation(latitude: 20, longitude: 20), previousWaypoint: firstWaypoint)
        let thirdWaypoint = Waypoint(pin: pin, location: CLLocation(latitude: 30, longitude: 30), previousWaypoint: secondWaypoint)

//        let pins = [pin]
//        let waypoints = [firstWaypoint, secondWaypoint, thirdWaypoint]
        
        let pinStatuses: [Pin: Waypoint] = [pin: thirdWaypoint]
        
        self.mapItems = pinStatuses.filter{$0.1._location != nil}.map {
            let annotation = MKPointAnnotation()
            annotation.title = "Pin"
            annotation.coordinate = $0.1.location!.coordinate
            return MapItem(pin: $0.0, waypoint: $0.1, annotation: annotation)
        }
            
        self.mapView.addAnnotations(self.mapItems.map{$0.annotation})
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
                pinInfoView.topAnchor.constraintEqualToAnchor(self.view.topAnchor),
            ]
            
            pinInfoView.hideConstraints = [
                pinInfoView.topAnchor.constraintEqualToAnchor(self.view.bottomAnchor),
            ]
  
            NSLayoutConstraint.activateConstraints([
                pinInfoView.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor, constant: 0),
                pinInfoView.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor, constant: 0),
                pinInfoView.heightAnchor.constraintEqualToAnchor(self.view.heightAnchor)
            ] + pinInfoView.hideConstraints)
            
            pinInfoView.layoutIfNeeded()

        }
        pinInfoView.mapItem = mapItem
        
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
        guard let currentWaypointLocation = mapItem.currentWaypoint.location else {
            print("No current waypoint location")
            return
        }
        let waypoint = Waypoint(pin: mapItem.pin, location: currentWaypointLocation, previousWaypoint: mapItem.currentWaypoint)
        
        //TODO: Save Waypoint
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