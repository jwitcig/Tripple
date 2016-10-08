//
//  AccountViewController.swift
//  Tripple
//
//  Created by Developer on 8/2/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

import AWSMobileHubHelper
import FBSDKLoginKit
import RealmSwift

class AccountViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var pinsCreatedLabel: UILabel!
    @IBOutlet weak var carriesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let userId = AWSIdentityManager.defaultIdentityManager().identityId else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let realm = try! Realm()
        
        let createdPinsCount = realm.objects(LocalPin).filter("_userId == %@", userId).count
        
        let dropsCount = realm.objects(LocalEvent).filter("_userId == %@", userId).filter("_type == %@", EventType.Drop.rawValue).count
        
        pinsCreatedLabel.text = createdPinsCount == 1 ? "\(createdPinsCount) Pin created" : "\(createdPinsCount) Pins created"
        carriesLabel.text = dropsCount == 1 ? "\(dropsCount) carry" : "\(dropsCount) carries"
        
        usernameLabel.text = AWSFacebookSignInProvider.sharedInstance().userName

        if let imageURL = AWSFacebookSignInProvider.sharedInstance().imageURL {
            if let imageData = NSData(contentsOfURL: imageURL) {
                imageView.image = UIImage(data: imageData)
            }
            
            
            imageView.clipsToBounds = false
            imageView.layer.shadowColor = UIColor.blackColor().CGColor
            imageView.layer.shadowOffset = CGSize(width: 5, height: 10)
            imageView.layer.shadowOpacity = 0.5
        }
        
        
        
    }
    
    @IBAction func signOutPressed(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { action in
            self.signOut()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func signOut() {
<<<<<<< HEAD
        AWSIdentityManager.defaultIdentityManager().logoutWithCompletionHandler { result, error in
=======
        AWSIdentityManager.default().logout { result, error in
            
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
            guard error == nil else {
                print("Error signing out: \(error!)")
                return
            }
<<<<<<< HEAD
            self.tabBarController?.dismissViewControllerAnimated(true, completion: nil)
=======
            
            self.tabBarController?.dismiss(animated: true, completion: nil)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        }
    }

}
