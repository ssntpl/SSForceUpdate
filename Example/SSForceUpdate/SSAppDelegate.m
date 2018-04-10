//
//  SSAppDelegate.m
//  SSForceUpdate
//
//  Created by Abhishek Kumar on 03/13/2018.
//  Copyright (c) 2018 Abhishek Kumar. All rights reserved.
//

#import "SSAppDelegate.h"
#import "SSForceUpdate.h"

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
    
    /* (Optional) If your application is not available in the U.S. App Store, you must specify the two-letter
     country code for the region in which your applicaiton is available. */
    //    [[SSForceUpdate sharedInstance] setCountryCode:@"en-US"];
    
    /* (Optional) Overrides system language to predefined language.
     Please use the SSForceUpdateLanguage constants defined in SSForceUpdate.h. */
    //    [[SSForceUpdate sharedInstance] setForceLanguageLocalization:SSForceUpdateLanguageRussian];
    
    // Turn on Debug statements
    [[SSForceUpdate sharedInstance] setDebugEnabled:true];
    
    // Perform check for new version of your app
  //  [[SSForceUpdate sharedInstance] checkVersion];
    [[SSForceUpdate sharedInstance] checkVersionWithNotificationPeriod];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    /*
     Perform daily check for new version of your app
     Useful if user returns to you app from background after extended period of time
     Place in applicationDidBecomeActive:
     
     Also, performs version check on first launch.
     */
    //    [[SSForceUpdate sharedInstance] checkVersionDaily];
    
    /*
     Perform weekly check for new version of your app
     Useful if you user returns to your app from background after extended period of time
     Place in applicationDidBecomeActive:
     
     Also, performs version check on first launch.
     */
        [[SSForceUpdate sharedInstance] checkVersionWithNotificationPeriod];
    
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
    //    [[SSForceUpdate sharedInstance] checkVersion];
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

