//
//  AWSMobileClient.swift
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
import Foundation
import UIKit
import AWSCore
import AWSMobileHubHelper
import AWSMobileAnalytics

/**
 * AWSMobileClient is a singleton that bootstraps the app. It creates an identity manager to establish the user identity with Amazon Cognito.
 */
class AWSMobileClient: NSObject {
    // Amazon Mobile Analytics client - Use to generate custom or monetization analytics events.
    var mobileAnalytics: AWSMobileAnalytics!
    
    // Shared instance of this class
    static let sharedInstance = AWSMobileClient()
    fileprivate var isInitialized: Bool
    
    fileprivate override init() {
        isInitialized = false
        super.init()
    }
    
    deinit {
        // Should never be called
        print("Mobile Client deinitialized. This should not happen.")
    }
    
    /**
     * Configure third-party services from application delegate with url, application
     * that called this provider, and any annotation info.
     *
     * - parameter application: instance from application delegate.
     * - parameter url: called from application delegate.
     * - parameter sourceApplication: that triggered this call.
     * - parameter annotation: from application delegate.
     * - returns: true if call was handled by this component
     */
    func withApplication(_ application: UIApplication, withURL url: URL, withSourceApplication sourceApplication: String?, withAnnotation annotation: AnyObject) -> Bool {
        print("withApplication:withURL")
        AWSIdentityManager.default().interceptApplication(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        
        if (!isInitialized) {
            isInitialized = true
        }
        
        return false;
    }
    
    /**
     * Performs any additional activation steps required of the third party services
     * e.g. Facebook
     *
     * - parameter application: from application delegate.
     */
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive:")
        initializeMobileAnalytics()
    }
    
    fileprivate func initializeMobileAnalytics() {
        if (mobileAnalytics == nil) {
            mobileAnalytics = AWSMobileAnalytics.default()
        }
    }
    
    /**
    * Configures all the enabled AWS services from application delegate with options.
    *
    * - parameter application: instance from application delegate.
    * - parameter launchOptions: from application delegate.
    */
    func didFinishLaunching(_ application: UIApplication, withOptions launchOptions: [AnyHashable: Any]?) -> Bool {
        print("didFinishLaunching:")

        let didFinishLaunching: Bool = AWSIdentityManager.default().interceptApplication(application, didFinishLaunchingWithOptions: launchOptions)

        if (!isInitialized) {
            AWSIdentityManager.default().resumeSession(completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
                print("Result: \(result) \n Error:\(error)")
            } as! (Any?, Error?) -> Void)
            isInitialized = true
        }

        return didFinishLaunching
    }
}
