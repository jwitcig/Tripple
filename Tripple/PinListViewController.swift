//
//  PinListViewController.swift
//  Tripple
//
//  Created by Developer on 7/30/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

import Firebase
import FirebaseDatabase

struct PinItem {
    let pin: Pin
    let events: [Event]
   
    init(pin: Pin, events: [Event]) {
        self.pin = pin
        self.events = events
    }
}

class PinListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var pins = [Pin]() {
        didSet {
            pickedUpPins = pins.filter { $0.currentEvent.type == EventType.Pickup.rawValue }
            droppedPins = pins.filter { $0.currentEvent.type == EventType.Drop.rawValue }
        }
    }
    var pickedUpPins = [Pin]()
    var droppedPins = [Pin]()
    
    var locationHandler = LocationHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let pinsRef = FIRDatabase.database().reference().child("pins")
        pinsRef.observe(.value, with: { snapshot in
            
            self.pins = snapshot.children.map{Pin(snapshot: $0 as! FIRDataSnapshot)}
            self.updateList()
        })
        
        locationHandler.executionBlock = { location, error in
            guard error == nil else { return }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        locationHandler.requestLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateList()
    }
    
    func updateList() {        
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return pickedUpPins.count
        case 1:
            return droppedPins.count
            
        default: fatalError("Unimplemented section")
        }        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor.clear
        
        var pin: Pin?
        
        switch (indexPath as NSIndexPath).section {
        case 0:
            pin = pickedUpPins[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = pin?.title
            
        case 1:
            pin = droppedPins[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = pin?.title

        default:
            fatalError("Unimplemented section")
        }
        
        if let currentLocation = locationHandler.location, let previousEventLocation = pin?.currentEvent.location {
            
            // distance in miles
            let distance = currentLocation.distance(from: previousEventLocation) * 0.000621371
            cell.detailTextLabel?.text = String(format: "%.2f", distance) + " mi"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return pickedUpPins.count > 0 ? "You're Carrying [\(pickedUpPins.count)]" : nil
        case 1:
            return droppedPins.count > 0 ? "Open Pins [\(droppedPins.count)]" : nil
        default:
            fatalError("Unimplemented section")
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var pin: Pin!
        
        switch (indexPath as NSIndexPath).section {
        case 0:
            pin = pickedUpPins[(indexPath as NSIndexPath).row]
            
        case 1:
            pin = droppedPins[(indexPath as NSIndexPath).row]
            
        default:
            fatalError("Unimplemented section")
        }
        
        
        guard let pinViewController = self.storyboard?.instantiateViewController(withIdentifier: "PinViewController") as? PinViewController else { return }
        
        pinViewController.pinID = pin.id

        self.present(pinViewController, animated: true, completion: nil)
    }
    
}
