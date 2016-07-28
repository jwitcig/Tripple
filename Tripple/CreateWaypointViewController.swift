//
//  FirstViewController.swift
//  Tripple
//
//  Created by Developer on 7/17/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import CoreLocation
import MapKit
import UIKit

class CreateWaypointViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var nameView: CreateWaypointNameView!
    @IBOutlet weak var messageView: CreateWaypointMessageView!
    @IBOutlet weak var viewCompleteWaypointView: ViewNewWaypointView!
    
    var locationManager = CLLocationManager()
    
    var currentLocation: CLLocation? {
        return locationManager.location
    }
    
    var processViewItems = [ProcessViewItem]()
    var currentItem: ProcessViewItem {
        return processViewItems[currentItemIndex]
    }
    var currentItemIndex = 0 {
        didSet {
            if currentItemIndex < 0 {
                currentItemIndex = 0
            } else if currentItemIndex == processViewItems.count {
                // process is complete
                createWaypoint()
                currentItemIndex -= 1
                return
            }
            
            updateProcessControls()
            slideToItem(processViewItems[currentItemIndex])
        }
    }
    
    struct ProcessViewItem {
        var view: UIView
        
        init(view: UIView) {
            self.view = view
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        locationManager.requestWhenInUseAuthorization()

        setupProcessViews()
        updateProcessControls()
        
        findLocation()
    }
    
    func findLocation() {
        // Request location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue) {
            
            // Checks for updated location 3 times
            for _ in 0..<10 {
                sleep(1)
                if self.currentLocation != nil {
                    // if location was updated, continue on
                    break
                }
            }
            
            if let location = self.currentLocation {
                self.viewCompleteWaypointView.coordinate = location.coordinate
                print("set location")
            } else {
                print("unable to retrieve location")
            }
        }
    }
    
    func setupProcessViews() {
        processViewItems = [nameView, messageView, viewCompleteWaypointView].map {
            $0.translatesAutoresizingMaskIntoConstraints = false
            
            stackView.addArrangedSubview($0)
            
            NSLayoutConstraint.activateConstraints([
                $0.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor),
            ])
            return ProcessViewItem(view: $0)
        }
    }
    
    func updateProcessControls() {
        let animationDuration = 0.8
        
        // back button
        if currentItemIndex == 0 {
            UIView.animateWithDuration(animationDuration) {
                self.backButton.enabled = false
                self.backButton.alpha = 0
            }
        } else {
            UIView.animateWithDuration(animationDuration) {
                self.backButton.enabled = true
                self.backButton.alpha = 1
            }
        }
        
        // next button
        if currentItemIndex == processViewItems.count - 1 {
            UIView.animateWithDuration(animationDuration) {
//                self.nextButton.enabled = false
//                self.nextButton.alpha = 0
            
                self.nextButton.setTitle("post", forState: .Normal)
                self.nextButton.setTitle("post", forState: .Selected)
            }
        } else {
            UIView.animateWithDuration(animationDuration) {
//                self.nextButton.enabled = true
//                self.nextButton.alpha = 1
                
                self.nextButton.setTitle("next", forState: .Normal)
                self.nextButton.setTitle("next", forState: .Selected)
            }
        }
    }
    
    func slideToItem(item: ProcessViewItem) {
        let index = (processViewItems.map{$0.view}).indexOf(item.view)
        
        guard let itemIndex = index else { return }
        
        if item.view == viewCompleteWaypointView {
            refreshCompletionView()
        }
        
        UIView.animateWithDuration(slideAnimationTime) { 
            self.scrollView.contentOffset = CGPoint(x: self.scrollView.frame.width*CGFloat(itemIndex), y: 0)
        }
    }
    
    let slideAnimationTime = 0.6
    func slideRight() {
        currentItemIndex += 1
    }
    
    func slideLeft() {
       currentItemIndex -= 1
    }
    
    @IBAction func nextPressed(sender: AnyObject) {
        slideRight()
    }
    
    @IBAction func backPressed(sender: AnyObject) {
        slideLeft()
    }
    
    func refreshCompletionView() {
        viewCompleteWaypointView.pinTitle = nameView.pinName
        viewCompleteWaypointView.pinMessage = messageView.pinMessage
        viewCompleteWaypointView.coordinate = currentLocation?.coordinate
    }
    
    func createWaypoint() {
        guard let location = self.currentLocation else {
            print("No location found: cannot save")
            return
        }
        
        let waypoint = Waypoint(location: location)
        
        let record = CKRecord(recordType: "Waypoint")
        record.setValue(waypoint.location, forKey: "location")
        
        CKContainer.defaultContainer().publicCloudDatabase.saveRecord(record) { (record, error) in
            
            guard error == nil else {
                print("Error saving record: \(error)")
                return
            }
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Failed: \(error)")
    }

}

private protocol ProcessView { }

class CreateWaypointNameView: UIView, ProcessView {
    @IBOutlet weak var textField: UITextField!
    
    var pinName: String? {
        get { return textField.text }
    }
}

class CreateWaypointMessageView: UIView, ProcessView, UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    var pinMessage: String? {
        get { return textView.text }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.recalculateVerticalAlignment()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        placeholderLabel.hidden = textView.hasText()
        textView.recalculateVerticalAlignment()

    }
    
    func textViewDidChange(textView: UITextView) {
        placeholderLabel.hidden = textView.hasText()
        textView.recalculateVerticalAlignment()

    }

}

class ViewNewWaypointView: UIView, ProcessView, MKMapViewDelegate {
  
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var pinTitle: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var pinMessage: String? {
        get { return messageLabel.text }
        set { messageLabel.text = newValue }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            
            guard let coordinate = coordinate else { return }
            
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: false)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let id = WaypointAnnotationView.reuseIdentifier!
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(id)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            annotationView!.image = UIImage(named: "mapPin")
        } else {
            //we are re-using a view, update its annotation reference...
            annotationView!.annotation = annotation
        }
        return annotationView
    }
}

extension UITextView {
        
    public func recalculateVerticalAlignment() {
        var y: CGFloat = (self.bounds.size.height - self.contentSize.height * self.zoomScale)/2.0;
        if y < 0 {
            y = 0
        }
        self.contentInset = UIEdgeInsets(top: y, left: 0, bottom: 0, right: 0)
    }
    
}
