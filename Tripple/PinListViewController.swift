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

<<<<<<< HEAD
        realmNotificationToken = pins.addNotificationBlock { change in
            dispatch_async(dispatch_get_main_queue()) {
                self.updateList()
            }
        }
        
        locationHandler.executionBlock = { location, error in
            guard error == nil else { return }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
=======
        realmNotificationToken = try! Realm().addNotificationBlock { notification, realm in
            DispatchQueue.main.async {
                self.displayData()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let userId = AWSIdentityManager.default().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        displayData()
        
        if CacheTransaction.cacheHasExpired(cacheType: .PersonalPickups, note: userId) {
            let realm = try! Realm()
            try! realm.write {
                realm.delete(realm.objects(LocalPickup.self))
            }
            
            let objectMapper = AWSDynamoDBObjectMapper.default()
            
            let pickupsScanExpression = AWSDynamoDBScanExpression()
            pickupsScanExpression.filterExpression = "#userId = :userId"
            pickupsScanExpression.expressionAttributeNames = ["#userId": "userId"]
            pickupsScanExpression.expressionAttributeValues = [":userId": AWSIdentityManager.default().identityId!]
            
            objectMapper.scan(CloudPickup.self, expression: pickupsScanExpression) { response, error in
                
                guard let response = response else {
                    print("no response")
                    return
                }
                
                guard let pickups = response.items as? [CloudPickup] else {
                    return
                }
                
                Syncer().writeToLocal(LocalPickup.self, cloudRepresentations: pickups)

                CacheTransaction.markCacheUpdated(cacheType: .PersonalPickups, note: userId)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
            }
        }
        locationHandler.requestLocation()
    }
    
<<<<<<< HEAD
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateList()
    }
    
    func updateList() {
        pinItems = pins.map(PinItem.init)
=======
    func displayData() {
        guard let userId = AWSIdentityManager.default().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        openItems = []
        pickedUpItems = []
        
        let realm = try! Realm()
        
        let pins = realm.objects(LocalPin.self)
        let waypoints = realm.objects(LocalWaypoint.self)
        
        let pinStatuses = realm.objects(LocalPinStatus.self)
        
        let currentPickups = realm.objects(LocalPickup.self).filter("_waypointId IN %@", pinStatuses.map{$0.waypointId}).filter("_userId = %@", userId)

        currentPickups.forEach { pickup in
            let pin = pins.filter{$0.id==pickup.pinId}.first
            let waypoint = waypoints.filter{$0.id==pickup.waypointId}.sorted{$0.0.createdDate.compare($0.1.createdDate) == .orderedDescending}.first
            
            if let pin = pin, let waypoint = waypoint {
                pickedUpItems.append(ClosedPinItem(pin: pin, currentWaypoint: waypoint, pickup: pickup))
            }
        }
        
        let pickupPinIds = currentPickups.map{$0.pinId}
        let openPins = pins.filter { !pickupPinIds.contains($0.id) }
        openPins.forEach { pin in
            let waypoint = waypoints.filter{$0.pinId==pin.id}.sorted{$0.0.createdDate.compare($0.1.createdDate) == .orderedDescending}.first
            
            if let waypoint = waypoint {
                openItems.append(OpenPinItem(pin: pin, currentWaypoint: waypoint))
            }
        }
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return pickedUpItems.count
        case 1:
            return droppedItems.count
            
        default: fatalError("Unimplemented section")
        }        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
<<<<<<< HEAD
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
=======
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor.clear

        switch (indexPath as NSIndexPath).section {
        case 0:
            let listItem = pickedUpItems[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = listItem.pin.title
            
        case 1:
            let listItem = openItems[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = listItem.pin.title
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8

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
    
<<<<<<< HEAD
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
=======
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        switch section {
        case 0:
            return pickedUpItems.count > 0 ? "You're Carrying [\(pickedUpItems.count)]" : nil
        case 1:
            return droppedItems.count > 0 ? "Open Pins [\(droppedItems.count)]" : nil
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
            pin = pickedUpItems[(indexPath as NSIndexPath).row].pin
            
        case 1:
<<<<<<< HEAD
            pin = droppedItems[indexPath.row].pin
=======
            pin = openItems[(indexPath as NSIndexPath).row].pin
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
            
        default:
            fatalError("Unimplemented section")
        }
        
        let pinId = pin.id
        
<<<<<<< HEAD
        guard let pinViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PinViewController") as? PinViewController else { return }
=======
        let presentationBlock = {
            DispatchQueue.main.async {
                guard let pinViewController = self.storyboard?.instantiateViewController(withIdentifier: "PinViewController") as? PinViewController else { return }
                
                pinViewController.pin = try! Realm().objectForPrimaryKey(LocalPin.self, key: pinId)
                
                self.present(pinViewController, animated: true, completion: nil)
            }
        }
        
        guard CacheTransaction.cacheHasExpired(cacheType: .PinWaypoints, note: pinId) else {
            presentationBlock()
            return
        }
        
        let mapper = AWSDynamoDBObjectMapper.default()
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        
        pinViewController.pinId = pinId
        
        self.presentViewController(pinViewController, animated: true, completion: nil)
    }
    
}
