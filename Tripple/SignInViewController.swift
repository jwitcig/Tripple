//
//  SignInViewController.swift
//  MySampleApp
//
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.2
//
//

import UIKit
import AWSMobileHubHelper
import FBSDKLoginKit
import GoogleSignIn

import AWSDynamoDB

class SignInViewController: UIViewController {

    @IBOutlet weak var facebookButton: UIButton!

    @IBOutlet weak var googleButton: UIButton!

// Support code for custom sign-in provider UI.
//    @IBOutlet weak var customProviderButton: UIButton!
//    @IBOutlet weak var customCreateAccountButton: UIButton!
//    @IBOutlet weak var customForgotPasswordButton: UIButton!
//    @IBOutlet weak var customUserIdField: UITextField!
//    @IBOutlet weak var customPasswordField: UITextField!
//    @IBOutlet weak var leftHorizontalBar: UIView!
//    @IBOutlet weak var rightHorizontalBar: UIView!
//    @IBOutlet weak var orSignInWithLabel: UIView!
    
    
    var didSignInObserver: AnyObject!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
         print("Sign In Loading.")
    
        didSignInObserver =  NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignIn,
            object: AWSIdentityManager.default(),
            queue: OperationQueue.main,
            using: {(note: Notification) -> Void in
                // perform successful login actions here
<<<<<<< HEAD

                self.performSegueWithIdentifier("LoginSuccess", sender: self)
=======
                
                self.performSegue(withIdentifier: "LoginSuccess", sender: self)
>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
        })

        // Facebook login permissions can be optionally set, but must be set
        // before user authenticates.
        AWSFacebookSignInProvider.sharedInstance().setPermissions(["public_profile"])
        

        // Facebook login behavior can be optionally set, but must be set
        // before user authenticates.
//        AWSFacebookSignInProvider.sharedInstance().setLoginBehavior(FBSDKLoginBehavior.Web.rawValue)

        // Facebook UI Setup
        facebookButton.addTarget(self, action: #selector(SignInViewController.handleFacebookLogin), for: .touchUpInside)

//                view.addConstraint(NSLayoutConstraint(item: googleButton, attribute: .Top, relatedBy: .Equal, toItem: anchorViewForGoogle(), attribute: .Bottom, multiplier: 1, constant: 8.0))
//                customProviderButton.removeFromSuperview()
//                customCreateAccountButton.removeFromSuperview()
//                customForgotPasswordButton.removeFromSuperview()
//                customUserIdField.removeFromSuperview()
//                customPasswordField.removeFromSuperview()
//                leftHorizontalBar.removeFromSuperview()
//                rightHorizontalBar.removeFromSuperview()
//                orSignInWithLabel.removeFromSuperview()
//                customProviderButton.setImage(UIImage(named: "LoginButton"), forState: .Normal)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(didSignInObserver)
    }
    
    func dimissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Utility Methods
    
    func handleLoginWithSignInProvider(_ signInProvider: AWSSignInProvider) {
        AWSIdentityManager.default().loginWithSign(signInProvider) { result, error in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
<<<<<<< HEAD
                dispatch_async(dispatch_get_main_queue()) {
                    
=======
                DispatchQueue.main.async {

>>>>>>> c1895d8be9fb31bb84b5a483d597d33bf21018f8
                }
            }
            print("result = \(result), error = \(error)")
        }
    }

    func showErrorDialog(_ loginProviderName: String, withError error: NSError) {
         print("\(loginProviderName) failed to sign in w/ error: \(error)")
        let alertController = UIAlertController(title: NSLocalizedString("Sign-in Provider Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."), preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label to cancel sign-in failure."), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - IBActions
    func handleFacebookLogin() {
        handleLoginWithSignInProvider(AWSFacebookSignInProvider.sharedInstance())
    }
    
    
    func handleGoogleLogin() {
        handleLoginWithSignInProvider(AWSGoogleSignInProvider.sharedInstance())
    }

}
