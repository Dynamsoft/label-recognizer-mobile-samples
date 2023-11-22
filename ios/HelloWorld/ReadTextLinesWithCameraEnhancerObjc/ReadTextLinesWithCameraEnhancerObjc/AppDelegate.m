/*
 * This is the sample of Dynamsoft Label Recognizer.
 *
 * Copyright © Dynamsoft Corporation.  All rights reserved.
 */

#import "AppDelegate.h"
#import <DynamsoftLicense/DynamsoftLicense.h>

@interface AppDelegate ()<DSLicenseVerificationListener>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Initialize license.
    // The license string here is a time-limited trial license. Note that network connection is required for this license to work.
    // You can also request an extension for your trial license in the customer portal: https://www.dynamsoft.com/customer/license/trialLicense?product=dlr&utm_source=installer&package=ios
    [DSLicenseManager initLicense:@"DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9" verificationDelegate:self];
    return YES;
}

- (void)onLicenseVerified:(BOOL)isSuccess error:(NSError *)error {
    if (error != nil) {
        NSString *msg = error.localizedDescription;
        NSLog(@"erver license verify failed, error:%@", msg);
    }
}

@end
