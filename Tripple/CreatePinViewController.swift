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

import AWSDynamoDB
import AWSMobileHubHelper

class CreatePinViewController: UIViewController, CLLocationManagerDelegate, ProcessViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var nameView: CreatePinNameView!
    @IBOutlet weak var messageView: CreatePinMessageView!
    @IBOutlet weak var viewCompletePinView: ViewNewPinView!
    
    var locationHandler = LocationHandler()
    
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
        
        locationHandler.executionBlock = { location, error in
            guard let location = location else {
                print("unable to retrieve location")
                return
            }
            
            self.viewCompletePinView.coordinate = location.coordinate
        }
        locationHandler.requestLocation()
        
        scrollView.isScrollEnabled = false

        setupProcessViews()
        updateProcessControls(proceedEnabled: false)
    }
    
    func processFormUpdate(form: ProcessView) {
        updateProcessControls(proceedEnabled: form.formComplete)
    }
    
    func setupProcessViews() {
        processViewItems = [nameView, messageView, viewCompletePinView].map {
            guard var processView = $0 as? ProcessView else { fatalError() }
            
            ($0 as AnyObject).translatesAutoresizingMaskIntoConstraints = false
            
            processView.formDelegate = self
            
            stackView.addArrangedSubview($0 as! UIView)
            
            NSLayoutConstraint.activate([
                ($0 as AnyObject).widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            ])
            return ProcessViewItem(view: $0 as! UIView)
        }
    }
    
    let animationDuration = 0.8
    func updateProcessControls(proceedEnabled: Bool? = nil) {
        
        // back button
        if currentItemIndex == 0 {
            UIView.animate(withDuration: animationDuration, animations: {
                self.backButton.isEnabled = false
                self.backButton.alpha = 0
            }) 
        } else {
            UIView.animate(withDuration: animationDuration, animations: {
                self.backButton.isEnabled = true
                self.backButton.alpha = 1
            }) 
        }
        
        // next button
        if currentItemIndex == processViewItems.count - 1 {
            self.nextButton.setTitle("drop", for: UIControlState())
            self.nextButton.setTitle("drop", for: .selected)
        } else {
            self.nextButton.setTitle("next", for: UIControlState())
            self.nextButton.setTitle("next", for: .selected)
        }
        
        if let enabled = proceedEnabled {
            self.nextButton.isEnabled = enabled
            
            if enabled {
                self.nextButton.alpha = 1
            } else {
                self.nextButton.alpha = 0.4
            }
        }
    }
    
    func slideToItem(_ item: ProcessViewItem) {
        processViewItems.forEach {
            ($0.view as? ProcessView)?.dismissKeyboard()
        }
        
        guard let itemIndex = (processViewItems.map{$0.view}).index(of: item.view) else { return }
        
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
        
        self.scrollView.isScrollEnabled = true
        self.scrollView.isUserInteractionEnabled = false

        UIView.animate(withDuration: slideAnimationTime, animations: {
            self.scrollView.contentOffset = CGPoint(x: self.scrollView.frame.width*CGFloat(itemIndex), y: 0)
            
        }, completion: { (finished) in
            self.scrollView.isScrollEnabled = false
            self.scrollView.isUserInteractionEnabled = true
        }) 
    }
    
    let slideAnimationTime = 0.6
    func slideRight() {
        currentItemIndex += 1
    }
    
    func slideLeft() {
       currentItemIndex -= 1
    }
    
    @IBAction func nextPressed(_ sender: AnyObject) {
        slideRight()
    }
    
    @IBAction func backPressed(_ sender: AnyObject) {
        slideLeft()
    }
    
    func refreshCompletionView() {
        viewCompletePinView.pinTitle = nameView.pinName
        viewCompletePinView.pinMessage = messageView.pinMessage
        viewCompletePinView.coordinate = locationHandler.location?.coordinate
    }
    
    func createPin() {
        guard let location = locationHandler.location else {
            print("No location found: cannot save")
            return
        }
        
        guard let userId = AWSIdentityManager.default().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        var pin = CloudPin()
        pin.userId = userId
        pin.title = nameView.pinName ?? "none"
        pin.message = messageView.pinMessage
        pin.createdDate = Date()
        
        let pinId = pin.id
        
        let objectMapper = AWSDynamoDBObjectMapper.default()

        objectMapper.save(pin) { error in
            guard error == nil else {
                print(error)
                
                return
            }
            
            var waypoint = CloudWaypoint()
            waypoint.pinId = pin.id
            waypoint.dropLocation = location
            waypoint.userId = userId
            waypoint.createdDate = Date()
            
            let waypointId = waypoint.id
            
            objectMapper.save(waypoint) { error in
                guard error == nil else {
                    print(error)
                    
                    objectMapper.remove(pin)

                    return
                }
                
                var pinStatus = CloudPinStatus()
                pinStatus?.pinId = pinId
                pinStatus?.waypointId = waypoint.id
                objectMapper.save(pinStatus!) { error in
                    guard error == nil else {
                        print(error)
                        
                        objectMapper.remove(waypoint)

                        return
                    }
                    
                    
                    var pickup = CloudPickup()
                    pickup.userId = userId
                    pickup.pinId = pinId
                    pickup.waypointId = waypointId
                    pickup.createdDate = Date()
                    objectMapper.save(pickup) { error in
                        guard error == nil else {
                            print(error)
                            
                            objectMapper.remove(pinStatus!)
                            
                            return
                        }
                        
                        let syncer = Syncer()
                        syncer.writeToLocal(LocalPin.self, cloudRepresentations: [pin])
                        syncer.writeToLocal(LocalWaypoint.self, cloudRepresentations: [waypoint])
                        syncer.writeToLocal(LocalPinStatus.self, cloudRepresentations: [pinStatus])
                        syncer.writeToLocal(LocalPickup.self, cloudRepresentations: [pickup])
                    }
                
                }
                
            }
            
            
            
        }

        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Failed: \(error)")
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

}

protocol ProcessView {
    var formDelegate: ProcessViewDelegate? { get set }
    
    var formComplete: Bool { get set }
    
    func dismissKeyboard()
}

protocol ProcessViewDelegate {
    func processFormUpdate(form: ProcessView)
}

class CreatePinNameView: UIView, ProcessView {
    
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField?.addTarget(self, action: #selector(CreatePinNameView.textFieldTextDidChange(_:)), for: .editingChanged)
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
    
    func textFieldTextDidChange(_ notification: Notification) {
        if textField.text?.characters.count == 0 {
            formComplete = false
        } else {
            formComplete = true
        }
    }
    
    func dismissKeyboard() {
        textField?.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
        textView.recalculateVerticalAlignment()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = textView.hasText
        textView.recalculateVerticalAlignment()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = textView.hasText
        textView.recalculateVerticalAlignment()

        formComplete = true
    }
    
    func dismissKeyboard() {
        textView?.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
            
            DispatchQueue.main.async {
                self.mapView.addAnnotation(annotation)
            }
        }
    }
    
    func dismissKeyboard() { }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let id = PinAnnotationView.reuseIdentifier!
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: id)
        
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

class LocationHandler: NSObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    var location: CLLocation?
    
    var executionBlock: ((_ location: CLLocation?, _ error: NSError?)->())?
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        executionBlock?(locations.first, nil)
        executionBlock = nil
        
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        executionBlock?(nil, error as NSError?)
    }
    
}
