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
    
    @IBAction func signOutPressed(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { action in
            self.signOut()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func signOut() {
        AWSIdentityManager.default().logout { result, error in
            
            guard error == nil else {
                print("Error signing out: \(error!)")
                return
            }
            
            self.tabBarController?.dismiss(animated: true, completion: nil)
        }
        
    }

}
