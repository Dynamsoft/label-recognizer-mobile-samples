/*
 * This is the sample of Dynamsoft Label Recognizer.
 *
 * Copyright © Dynamsoft Corporation.  All rights reserved.
 */

import UIKit
import DynamsoftLicense

@main
class AppDelegate: UIResponder, UIApplicationDelegate, LicenseVerificationListener {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize license.
        // The license string here is a time-limited trial license. Note that network connection is required for this license to work.
        // You can also request a 30-day trial license via the Request a Trial License link: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=github&package=ios

        LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", verificationDelegate:self)
        return true
    }

    func onLicenseVerified(_ isSuccess: Bool, error: Error?) {
        if(error != nil)
        {
            if let msg = error?.localizedDescription {
                print("Server license verify failed, error:\(msg)")
            }
        }
    }
}

