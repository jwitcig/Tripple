//
//  AccountViewController.swift
//  Tripple
//
//  Created by Developer on 8/2/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import UIKit

import Firebase
import FirebaseAuth

class AccountViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var pinsCreatedLabel: UILabel!
    @IBOutlet weak var carriesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let userId = FIRAuth.auth()?.currentUser?.uid else {
            let alert = UIAlertController(title: "Sign In Error", message: "User account could not be verified, try logging in again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
//        
//        
//        let createdPinsCount = realm.objects(LocalPin).filter("_userId == %@", userId).count
//        
//        let dropsCount = realm.objects(LocalEvent).filter("_userId == %@", userId).filter("_type == %@", EventType.Drop.rawValue).count
//        
//        pinsCreatedLabel.text = createdPinsCount == 1 ? "\(createdPinsCount) Pin created" : "\(createdPinsCount) Pins created"
//        carriesLabel.text = dropsCount == 1 ? "\(dropsCount) carry" : "\(dropsCount) carries"
        
        usernameLabel.text = userId

//        if let imageURL = AWSFacebookSignInProvider.sharedInstance().imageURL {
//            if let imageData = NSData(contentsOfURL: imageURL) {
//                imageView.image = UIImage(data: imageData)
//            }
//            
//            imageView.clipsToBounds = false
//            imageView.layer.shadowColor = UIColor.blackColor().CGColor
//            imageView.layer.shadowOffset = CGSize(width: 5, height: 10)
//            imageView.layer.shadowOpacity = 0.5
//        }
    
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
        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            print("Error signing out")
        }
        
    }

}
