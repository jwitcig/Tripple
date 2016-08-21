//
//  PinListViewController.swift
//  Tripple
//
//  Created by Developer on 7/30/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

import AWSDynamoDB
import AWSMobileHubHelper
import RealmSwift

struct PinItem {
    var pin: LocalPin
    
    init(pin: LocalPin) {
        self.pin = pin
    }
}

class PinListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var pinItems = [PinItem]() {
        didSet {
            pickedUpItems = pinItems.filter { $0.pin.currentEvent?.type == EventType.Pickup.rawValue }
            droppedItems = pinItems.filter { $0.pin.currentEvent?.type == EventType.Drop.rawValue }
        }
    }
    var pickedUpItems = [PinItem]()
    var droppedItems = [PinItem]()
    
    var realmNotificationToken: NotificationToken?
    
    var locationHandler = LocationHandler()
    
    let pins = try! Realm().objects(LocalPin.self)
   
    override func viewDidLoad() {
        super.viewDidLoad()

        realmNotificationToken = pins.addNotificationBlock { change in
            dispatch_async(dispatch_get_main_queue()) {
                self.updateList()
            }
        }
        
        locationHandler.executionBlock = { location, error in
            guard error == nil else { return }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
        locationHandler.requestLocation()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateList()
    }
    
    func updateList() {
        pinItems = pins.map(PinItem.init)
        
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return pickedUpItems.count
        case 1:
            return droppedItems.count
            
        default: fatalError("Unimplemented section")
        }        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        cell.backgroundColor = UIColor.clearColor()
        
        var listItem: PinItem?
        
        switch indexPath.section {
        case 0:
            listItem = pickedUpItems[indexPath.row]
            cell.textLabel?.text = listItem?.pin.title
            
        case 1:
            listItem = droppedItems[indexPath.row]
            cell.textLabel?.text = listItem?.pin.title

        default:
            fatalError("Unimplemented section")
        }
        
        if let currentLocation = locationHandler.location, let previousEventLocation = listItem?.pin.currentEvent?.location {
            
            // distance in miles
            let distance = currentLocation.distanceFromLocation(previousEventLocation) * 0.000621371
            cell.detailTextLabel?.text = String(format: "%.2f", distance) + " mi"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return pickedUpItems.count > 0 ? "You're Carrying [\(pickedUpItems.count)]" : nil
        case 1:
            return droppedItems.count > 0 ? "Open Pins [\(droppedItems.count)]" : nil
        default:
            fatalError("Unimplemented section")
        }

    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var pin: Pin!
        
        switch indexPath.section {
        case 0:
            pin = pickedUpItems[indexPath.row].pin
            
        case 1:
            pin = droppedItems[indexPath.row].pin
            
        default:
            fatalError("Unimplemented section")
        }
        
        let pinId = pin.id
        
        guard let pinViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PinViewController") as? PinViewController else { return }
        
        pinViewController.pinId = pinId
        
        self.presentViewController(pinViewController, animated: true, completion: nil)
    }
    
}
