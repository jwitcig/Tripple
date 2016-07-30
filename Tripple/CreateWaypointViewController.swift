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

class CreatePinViewController: UIViewController, CLLocationManagerDelegate, ProcessViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var nameView: CreatePinNameView!
    @IBOutlet weak var messageView: CreatePinMessageView!
    @IBOutlet weak var viewCompletePinView: ViewNewPinView!
    
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
                createPin()
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
        
        scrollView.scrollEnabled = false

        setupProcessViews()
        updateProcessControls(proceedEnabled: false)
        
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
                self.viewCompletePinView.coordinate = location.coordinate
                print("set location")
            } else {
                print("unable to retrieve location")
            }
        }
    }
    
    func processFormUpdate(form form: ProcessView) {
        updateProcessControls(proceedEnabled: form.formComplete)
    }
    
    func setupProcessViews() {
        processViewItems = [nameView, messageView, viewCompletePinView].map {
            guard var processView = $0 as? ProcessView else { fatalError() }
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            
            processView.formDelegate = self
            
            stackView.addArrangedSubview($0)
            
            NSLayoutConstraint.activateConstraints([
                $0.widthAnchor.constraintEqualToAnchor(scrollView.widthAnchor),
            ])
            return ProcessViewItem(view: $0)
        }
    }
    
    let animationDuration = 0.8
    func updateProcessControls(proceedEnabled proceedEnabled: Bool? = nil) {
        
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
            self.nextButton.setTitle("drop", forState: .Normal)
            self.nextButton.setTitle("drop", forState: .Selected)
        } else {
            self.nextButton.setTitle("next", forState: .Normal)
            self.nextButton.setTitle("next", forState: .Selected)
        }
        
        if let enabled = proceedEnabled {
            self.nextButton.enabled = enabled
            
            if enabled {
                self.nextButton.alpha = 1
            } else {
                self.nextButton.alpha = 0.4
            }
        }
    }
    
    func slideToItem(item: ProcessViewItem) {
        processViewItems.forEach {
            ($0.view as? ProcessView)?.dismissKeyboard()
        }
        
        guard let itemIndex = (processViewItems.map{$0.view}).indexOf(item.view) else { return }
        
        let processView = item.view as! ProcessView
        
        updateProcessControls(proceedEnabled: processView.formComplete)
        
        switch item.view {
            
        case nameView:
            break
            
        case messageView:
            break
            
        case viewCompletePinView:
            refreshCompletionView()

        default:
            print("Unimplemented view: 'slideToItem:'")
        }
        
        self.scrollView.scrollEnabled = true
        self.scrollView.userInteractionEnabled = false

        UIView.animateWithDuration(slideAnimationTime, animations: {
            self.scrollView.contentOffset = CGPoint(x: self.scrollView.frame.width*CGFloat(itemIndex), y: 0)
            
        }) { (finished) in
            self.scrollView.scrollEnabled = false
            self.scrollView.userInteractionEnabled = true
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
        viewCompletePinView.pinTitle = nameView.pinName
        viewCompletePinView.pinMessage = messageView.pinMessage
        viewCompletePinView.coordinate = currentLocation?.coordinate
    }
    
    func createPin() {
        guard let location = self.currentLocation else {
            print("No location found: cannot save")
            return
        }
        
        let pin = Pin()
        pin._title = nameView.pinName
        pin._message = messageView.pinMessage
        
        let waypoint = Waypoint(pin: pin, location: location)
        
//        let record = CKRecord(recordType: "Pin")
//        record.setValue(pin.location, forKey: "location")
//        
//        CKContainer.defaultContainer().publicCloudDatabase.saveRecord(record) { (record, error) in
//            
//            guard error == nil else {
//                print("Error saving record: \(error)")
//                return
//            }
//        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Failed: \(error)")
    }

}

protocol ProcessView {
    var formDelegate: ProcessViewDelegate? { get set }
    
    var formComplete: Bool { get set }
    
    func dismissKeyboard()
}

protocol ProcessViewDelegate {
    func processFormUpdate(form form: ProcessView)
}

class CreatePinNameView: UIView, ProcessView {
    
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField?.addTarget(self, action: #selector(CreatePinNameView.textFieldTextDidChange(_:)), forControlEvents: .EditingChanged)
        }
    }
    
    var formDelegate: ProcessViewDelegate?
    
    var formComplete = false {
        didSet {
            formDelegate?.processFormUpdate(form: self)
        }
    }
    
    var pinName: String? {
        get { return textField.text }
    }
    
    func textFieldTextDidChange(notification: NSNotification) {
        if textField.text?.characters.count == 0 {
            formComplete = false
        } else {
            formComplete = true
        }
    }
    
    func dismissKeyboard() {
        textField?.resignFirstResponder()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
    }
    
}

class CreatePinMessageView: UIView, ProcessView, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    var formDelegate: ProcessViewDelegate?
    
    var formComplete = true {
        didSet {
            formDelegate?.processFormUpdate(form: self)
        }
    }
    
    var pinMessage: String? {
        get { return textView.text }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        placeholderLabel.hidden = true
        textView.recalculateVerticalAlignment()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        placeholderLabel.hidden = textView.hasText()
        textView.recalculateVerticalAlignment()
    }
    
    func textViewDidChange(textView: UITextView) {
        placeholderLabel.hidden = textView.hasText()
        textView.recalculateVerticalAlignment()

        formComplete = true
    }
    
    func dismissKeyboard() {
        textView?.resignFirstResponder()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        dismissKeyboard()
    }

}

class ViewNewPinView: UIView, ProcessView, MKMapViewDelegate {
  
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
   
    var formDelegate: ProcessViewDelegate?
    
    var formComplete = true {
        didSet {
            formDelegate?.processFormUpdate(form: self)
        }
    }
    
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
    
    func dismissKeyboard() { }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let id = PinAnnotationView.reuseIdentifier!
        
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
