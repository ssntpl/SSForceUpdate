//
//  SSForceUpdate.h
//  Pods-SSForceUpdate_Example
//
//  Created by Sword Software on 13/03/18.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//! Project version number for SSForceUpdate.
FOUNDATION_EXPORT double SSForceUpdateVersionNumber;

//! Project version string for SSForceUpdate.
FOUNDATION_EXPORT const unsigned char SSForceUpdateVersionString[];

@protocol SSForceUpdateDelegate <NSObject>

@optional
- (void)SSForceUpdateDidShowUpdateDialog;       // User presented with update dialog
- (void)SSForceUpdateUserDidLaunchAppStore;     // User did click on button that launched App Store.app
- (void)SSForceUpdateUserDidSkipVersion;        // User did click on button that skips version update
- (void)SSForceUpdateUserDidCancel;             // User did click on button that cancels update dialog
- (void)SSForceUpdateDidDetectNewVersionWithoutAlert:(NSString *)message; // SSForceUpdate performed version check and did not display alert
@end

typedef NS_ENUM(NSUInteger, SSForceUpdateAlertType)
{
    SSForceUpdateAlertTypeForce = 1,    // Forces user to update your app
    SSForceUpdateAlertTypeOption,       // (DEFAULT) Presents user with option to update app now or at next launch
    SSForceUpdateAlertTypeSkip,         // Presents User with option to update the app now, at next launch, or to skip this version all together
    SSForceUpdateAlertTypeNone          // Don't show the alert type , useful for skipping Patch, Minor, Major updates
};

@interface SSForceUpdate : NSObject

/**
 The SSForceUpdate delegate can be used to know when the update dialog is shown and which action a user took.
 See the protocol declaration above.
 */
@property (nonatomic, weak) id<SSForceUpdateDelegate> delegate;

/**
 The UIViewController that will present an instance of UIAlertController
 */
@property (nonatomic, strong) UIViewController *presentingViewController;

/**
 The current version of your app that is available for download on the App Store
 */
@property (nonatomic, copy, readonly) NSString *currentAppStoreVersion;


/**
 @b OPTIONAL: The preferred name for the app. This name will be displayed in the @c UIAlertView in place of the bundle name.
 */
@property (nonatomic, strong) NSString *appName;

/**
 @b OPTIONAL: Log Debug information
 */
@property (nonatomic, assign, getter=isDebugEnabled) BOOL debugEnabled;

/**
 @b OPTIONAL: The alert type to present to the user when there is an update. See the @c SSForceUpdateAlertType enum above.
 */
@property (nonatomic, assign) SSForceUpdateAlertType alertType;

/**
 @b OPTIONAL: The alert type to present to the user when there is a major update (e.g. A.b.c.d). See the @c SSForceUpdateAlertType enum above.
 */
@property (nonatomic, assign) SSForceUpdateAlertType majorUpdateAlertType;

/**
 @b OPTIONAL: The alert type to present to the user when there is a minor update (e.g. a.B.c.d). See the @c SSForceUpdateAlertType enum above.
 */
@property (nonatomic, assign) SSForceUpdateAlertType minorUpdateAlertType;

/**
 @b OPTIONAL: The alert type to present to the user when there is a patch update (e.g. a.b.C.d). See the @c SSForceUpdateAlertType enum above.
 */
@property (nonatomic, assign) SSForceUpdateAlertType patchUpdateAlertType;

/**
 @b OPTIONAL: The alert type to present to the user when there is a minor update (e.g. a.b.c.D). See the @c SSForceUpdateAlertType enum above.
 */
@property (nonatomic, assign) SSForceUpdateAlertType revisionUpdateAlertType;

/**
 @b OPTIONAL: If your application is not availabe in the U.S. Store, you must specify the two-letter
 country code for the region in which your applicaiton is available in.
 */
@property (nonatomic, copy) NSString *countryCode;

/**
 @b OPTIONAL: Overides system language to predefined language. Please use the @c SSForceUpdateLanguage constants defined in @c SSForceUpdate.h.
 */
@property (nonatomic, copy) NSString *forceLanguageLocalization;

/**
 @b OPTIONAL: The tintColor for the alertController
 */
@property (nonatomic, strong) UIColor *alertControllerTintColor;

/**
 @b OPTIONAL: Delays the update prompt by a specific number of days. By default, this value is set to 1 day to avoid an issue where Apple updates the JSON faster than the app binary propogates to the App Store.
 */
@property (nonatomic, assign) NSUInteger showAlertAfterCurrentVersionHasBeenReleasedForDays;

#pragma mark - Methods

/**
 SSForceUpdate's Singleton method
 */
+ (SSForceUpdate *)sharedInstance;

/**
 Checks the installed version of your application against the version currently available app version on your JSON file.
 If a newer version exists in the AppStore or JSON file, SSForceUpdate prompts your user to update their copy of your app.
 */
- (void)checkVersion;

/**
 Perform check for new version of your app when a specific period of time met.
 Useful if user returns to you app from background after extended period of time.
 Place in @c applicationDidBecomeActive:.
 */
- (void)checkVersionWithNotificationPeriod;

@end

