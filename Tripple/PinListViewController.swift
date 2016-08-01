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

protocol ListItem {
    var pin: Pin { get }
    var currentWaypoint: Waypoint { get }
}

class PinListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var pickedUpItems = [ClosedPinItem]()
    var openItems = [OpenPinItem]()
   
    struct ClosedPinItem: ListItem {
        var pin: Pin
        var currentWaypoint: Waypoint
        var pickup: Pickup

        init(pin: Pin, currentWaypoint: Waypoint, pickup: Pickup) {
            self.pin = pin
            self.currentWaypoint = currentWaypoint
            self.pickup = pickup
        }
    }
    
    struct OpenPinItem: ListItem {
        var pin: Pin
        var currentWaypoint: Waypoint
        
        init(pin: Pin, currentWaypoint: Waypoint) {
            self.pin = pin
            self.currentWaypoint = currentWaypoint
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        
        let pins = realm.objects(LocalPin.self)
        let waypoints = realm.objects(LocalWaypoint.self)
        
        let pickups = realm.objects(LocalPickup.self)
        
        pickups.forEach { pickup in
            let pin = pins.filter{$0.id==pickup.pinId}.first
            let waypoint = waypoints.filter{$0.id==pickup.waypointId}.sort{$0.0.createdDate.compare($0.1.createdDate) == .OrderedDescending}.first
            
            if let pin = pin, let waypoint = waypoint {
                pickedUpItems.append(ClosedPinItem(pin: pin, currentWaypoint: waypoint, pickup: pickup))
            }
        }
        
        let pickupPinIds = pickups.map{$0.pinId}
        let openPins = pins.filter { !pickupPinIds.contains($0.id) }
        openPins.forEach { pin in
            let waypoint = waypoints.filter{$0.pinId==pin.id}.sort{$0.0.createdDate.compare($0.1.createdDate) == .OrderedDescending}.first
            
            if let waypoint = waypoint {
                openItems.append(OpenPinItem(pin: pin, currentWaypoint: waypoint))
            }
        }
        
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
            return openItems.count
            
        default: fatalError("Unimplemented section")
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor.clearColor()

        switch indexPath.section {
        case 0:
            let listItem = pickedUpItems[indexPath.row]
            cell.textLabel?.text = listItem.pin.title
            
        case 1:
            let listItem = openItems[indexPath.row]
            cell.textLabel?.text = listItem.pin.title

        default:
            fatalError("Unimplemented section")
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var pin: Pin!
        
        switch indexPath.section {
        case 0:
            pin = pickedUpItems[indexPath.row].pin
            
        case 1:
            pin = openItems[indexPath.row].pin
            
        default:
            fatalError("Unimplemented section")
        }
        
        let pinId = pin.id
        
        let mapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        let query = AWSDynamoDBScanExpression()
        query.filterExpression = "#pinId = :pinId"
        query.expressionAttributeNames = ["#pinId": "pinId"]
        query.expressionAttributeValues = [":pinId": pin.id]
        mapper.scan(CloudWaypoint.self, expression: query) { response, error in
            
            guard let response = response else {
                print("error: \(error)")
                return
            }
            
            guard let waypoints = response.items as? [CloudWaypoint] else { return }
            
            let syncer = Syncer()
            _ = syncer.writeToLocal(LocalWaypoint.self, cloudRepresentations: waypoints)
            

            dispatch_async(dispatch_get_main_queue()) {
                guard let pinViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PinViewController") as? PinViewController else { return }
                
                pinViewController.pin = try! Realm().objectForPrimaryKey(LocalPin.self, key: pinId)

                self.presentViewController(pinViewController, animated: true, completion: nil)
            }
        }

        
    }
    
}
