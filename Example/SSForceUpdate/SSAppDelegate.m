//
//  SSAppDelegate.m
//  SSForceUpdate
//
//  Created by Abhishek Kumar on 03/13/2018.
//  Copyright (c) 2018 Abhishek Kumar. All rights reserved.
//

#import "SSAppDelegate.h"
#import "SSForceUpdate.h"

// HOST_URL is the URL that contains the JSON where all the details must be stored related to the app that has been released to the appstore.
/**
 {
 "results": {
 "appID": 1301873090,
 "currentVersionReleaseDate": "2018-02-07T03:18:02Z",
 "minimumOSVersion": "9.0",
 "minimumStableVersion": "1.0.0",
 "version": "1.0.0",
 "notificationPeriodInDays": 7,
 "enable": true,
 "force": true
 }
 }
 */
#define HOST_URL (@"https://api.myjson.com/bins/186hh7")

@implementation SSAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Present Window before calling SSForceUpdate
  //  [self.window makeKeyAndVisible];
    
    // Set the UIViewController that will present an instance of UIAlertController
    [[SSForceUpdate sharedInstance] setPresentingViewController:_window.rootViewController];
    
    // (Optional) Set the Delegate to track what a user clicked on, or to use a custom UI to present your message.
    [[SSForceUpdate sharedInstance] setDelegate:self];
    
    // (Optional) When this is set, the alert will only show up if the current version has already been released for X days.
    // By default, this value is set to 1 (day) to avoid an issue where Apple updates the JSON faster than the app binary propogates to the App Store.
    //    [[SSForceUpdate sharedInstance] setShowAlertAfterCurrentVersionHasBeenReleasedForDays:3];
    
    // (Optional) The tintColor for the alertController
    //    [[SSForceUpdate sharedInstance] setAlertControllerTintColor:[UIColor purpleColor]];
    
    // (Optional) Set the App Name for your app
    //    [[SSForceUpdate sharedInstance] setAppName:@"iTunes Connect Mobile"];
    
    /* (Optional) Set the Alert Type for your app
     By default, SSForceUpdate is configured to use SSForceUpdateAlertTypeOption */
  //  [[SSForceUpdate sharedInstance] setAlertType:SSForceUpdateAlertTypeOption];
    
    // Turn on Debug statements
    [[SSForceUpdate sharedInstance] setDebugEnabled:true];
    
    // Perform check for new version of your app
  //  [[SSForceUpdate sharedInstance] checkVersion];
    NSString *url = [NSString stringWithFormat:HOST_URL];
    [[SSForceUpdate sharedInstance] checkVersionWithNotificationPeriod:url];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    /*
     Perform weekly check for new version of your app
     Useful if you user returns to your app from background after extended period of time
     Place in applicationDidBecomeActive:
     
     Also, performs version check on first launch.
     */
    NSString *url = [NSString stringWithFormat:HOST_URL];
    [[SSForceUpdate sharedInstance] checkVersionWithNotificationPeriod:url];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Perform check for new version of your app
     Useful if user returns to you app from background after being sent tot he App Store,
     but doesn't update their app before coming back to your app.
     
     ONLY USE THIS IF YOU ARE USING *SSForceUpdateAlertTypeForce*
     
     Also, performs version check on first launch.
     */
}

#pragma mark - SSForceUpdateDelegate
- (void)SSForceUpdateDidShowUpdateDialog
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)SSForceUpdateUserDidLaunchAppStore
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)SSForceUpdateUserDidSkipVersion
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)SSForceUpdateUserDidCancel
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)SSForceUpdateDidDetectNewVersionWithoutAlert:(NSString *)message
{
    NSLog(@"%@", message);
}

@end

