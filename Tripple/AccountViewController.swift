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

class AccountViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func signOutPressed(sender: AnyObject) {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Sign Out", style: .Destructive) { action in
            self.signOut()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func signOut() {
        AWSIdentityManager.defaultIdentityManager().logoutWithCompletionHandler { result, error in
            
            guard error == nil else {
                print("Error signing out: \(error!)")
                return
            }
            
            self.tabBarController?.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }

}
