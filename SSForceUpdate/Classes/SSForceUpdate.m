//
//  SSForceUpdate.m
//  Pods-SSForceUpdate_Example
//
//  Created by Sword Software on 13/03/18.
//

#import "SSForceUpdate.h"

/// NSUserDefault macros to store user's preferences for SSForceUpdateAlertTypeSkip
NSString * const SSForceUpdateDefaultSkippedVersion         = @"skip_version_update";
NSString * const SSForceUpdateLastVersionCheckStoredDate = @"last_version_check_stored_date";

NSString * const SSForceUpdateNotificationPeriodInDays = @"notification_period_in_days";

@interface SSForceUpdate()

@property (nonatomic, strong) NSDictionary <NSString *, id> *appData;
@property (nonatomic, strong) NSDate *lastVersionCheckPerformedOnDate;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *currentInstalledVersion;
@property (nonatomic, copy) NSString *minimumStableVersion;
@property (nonatomic, copy) NSString *currentAppStoreVersion;
@property (nonatomic, copy) NSString *updateAvailableMessage;
@property (nonatomic, copy) NSString *theNewVersionMessage;
@property (nonatomic, copy) NSString *updateButtonText;
@property (nonatomic, copy) NSString *nextTimeButtonText;
@property (nonatomic, copy) NSString *remindMeAfterCertainPeriodButtonText;
@property (nonatomic, copy) NSString *skipButtonText;

@property (nonatomic) NSInteger notificationPeriodInDays;

@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation SSForceUpdate

#pragma mark - Initialization

+ (SSForceUpdate *)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        _alertType = SSForceUpdateAlertTypeOption;
        _lastVersionCheckPerformedOnDate = [[NSUserDefaults standardUserDefaults] objectForKey:SSForceUpdateLastVersionCheckStoredDate];
        _notificationPeriodInDays = [[[NSUserDefaults standardUserDefaults] objectForKey:SSForceUpdateNotificationPeriodInDays] integerValue];
        _currentInstalledVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _showAlertAfterCurrentVersionHasBeenReleasedForDays = 1;
    }
    
    return self;
}

#pragma mark - Public

- (void)checkVersion {
    if (!_presentingViewController) {
        NSLog(@"[SSForceUpdate]: Please make sure that you have set presentationViewController before calling checkVersion.");
    } else {
        [self performVersionCheck];
    }
}

- (void)checkVersionWithNotificationPeriod {
    /*
     On app's first launch, lastVersionCheckPerformedOnDate isn't set.
     Avoid false-positive fulfilment of second condition in this method.
     Also, performs version check on first launch.
     */
    if (![self lastVersionCheckPerformedOnDate]) {
        
        // Perform First Launch Check
        [self checkVersion];
    } else {
      
        [self printDebugMessage:[NSString stringWithFormat:@"Notification period = %ld", (long)self.notificationPeriodInDays]];
        [self printDebugMessage:[NSString stringWithFormat:@"Last version checked date = %@", [self lastVersionCheckPerformedOnDate]]];
        [self printDebugMessage:[NSString stringWithFormat:@"Number of days Elapsed = %ld", (long)[self numberOfDaysElapsedBetweenLastVersionCheckDate]]];
        
        // If weekly condition is satisfied, perform version check
        if(self.notificationPeriodInDays) {
            if ([self numberOfDaysElapsedBetweenLastVersionCheckDate] >= self.notificationPeriodInDays) {
                self.alertType = SSForceUpdateAlertTypeForce;
                [self checkVersion];
            } else {
                
            }
        }  else {
            [self checkVersion];
        }
    }
}

#pragma mark - Helpers
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
- (void)performVersionCheck {
    NSString *storeURLString = [NSString stringWithFormat:@"https://api.myjson.com/bins/186hh7"];
    NSURL *storeURL = [NSURL URLWithString:storeURLString]; //
  
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:storeURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    
    [self printDebugMessage:[NSString stringWithFormat:@"storeURL: %@", storeURL]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if ([data length] > 0 && !error) { // Success
                                                    [self parseResults:data];
                                                }
                                            }];
    [task resume];
}

- (void)parseResults:(NSData *)data {
    _appData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    [self printDebugMessage:[NSString stringWithFormat:@"JSON Results: %@", _appData]];
    
    if ([self isUpdateCompatibleWithDeviceOS:_appData]) {
        
        __typeof__(self) __weak weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSDictionary<NSString *, id> *results = [self.appData valueForKey:@"results"];
            
            NSString *releaseDateString = [results valueForKey:@"currentVersionReleaseDate"];
            if (releaseDateString == nil) {
                return;
            } else {
                NSInteger daysSinceRelease = [weakSelf daysSinceDateString:releaseDateString];
                if (!(daysSinceRelease >= weakSelf.showAlertAfterCurrentVersionHasBeenReleasedForDays)) {
                    NSString *message = [NSString stringWithFormat:@"Your app has been released for %ld days, but SSForceUpdate cannot prompt the user until %lu days have passed.", (long)daysSinceRelease, (unsigned long)weakSelf.showAlertAfterCurrentVersionHasBeenReleasedForDays];
                    [self printDebugMessage:message];
                    return;
                }
            }
            
            /**
             Current version that has been uploaded to the AppStore.
             Used to contain all versions, but now only contains the latest version.
             */
            
            NSString *versionsInAppStore = [results valueForKey:@"version"];
            if (versionsInAppStore == nil) {
                return;
            } else {
                weakSelf.currentAppStoreVersion = versionsInAppStore; //[versionsInAppStore objectAtIndex:0];
                    if ([weakSelf isAppStoreVersionNewer:weakSelf.currentAppStoreVersion]) {
                        
                        if([[results valueForKey:@"force"] integerValue]) {
                             self.alertType = SSForceUpdateAlertTypeForce;
                        } else {
                            self.minimumStableVersion = [results valueForKey:@"minimumStableVersion"];
                            
                            if([self.minimumStableVersion caseInsensitiveCompare:self.currentInstalledVersion] == NSOrderedDescending) {
                                self.alertType = SSForceUpdateAlertTypeForce;
                            } else if([self.minimumStableVersion caseInsensitiveCompare:self.currentInstalledVersion] == NSOrderedAscending || [self.minimumStableVersion caseInsensitiveCompare:self.currentInstalledVersion] == NSOrderedSame) {
                                if([[results valueForKey:@"notificationPeriodInDays"] integerValue]) {
                                    self.alertType = SSForceUpdateAlertTypeOption;
                                } else {
                                    self.alertType = SSForceUpdateAlertTypeForce;
                                }
                                
                            }
                            
                            
                        }
                        
                        [weakSelf appStoreVersionIsNewer:weakSelf.currentAppStoreVersion];
                        
                    } else {
                        [self printDebugMessage:@"You have already installed the latest version"];
                    }
            }
        });
    } else {
        [self printDebugMessage:@"Device is incompatible with installed verison of iOS."];
    }
}

- (BOOL)isUpdateCompatibleWithDeviceOS:(NSDictionary*)appData {
    NSDictionary *results = appData[@"results"]; // NSArray<NSDictionary<NSString *, id> *>
    
    if (results.count > 0) {
        NSString *requiresOSVersion = results[@"minimumOSVersion"]; //[results firstObject][@"minimumOsVersion"];
        if (requiresOSVersion != nil) {
            NSString *systemVersion = [UIDevice currentDevice].systemVersion;
            if (
                ([systemVersion compare:requiresOSVersion options:NSNumericSearch] == NSOrderedDescending) ||
                ([systemVersion compare:requiresOSVersion options:NSNumericSearch] == NSOrderedSame)
                ) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    } else {
        return false;
    }
}

- (NSUInteger)numberOfDaysElapsedBetweenLastVersionCheckDate {
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [currentCalendar components:NSCalendarUnitDay
                                                      fromDate:[self lastVersionCheckPerformedOnDate]
                                                        toDate:[NSDate date]
                                                       options:0];
    return [components day];
}

- (BOOL)isAppStoreVersionNewer:(NSString *)currentAppStoreVersion {
    // Current installed version is the newest public version or newer (e.g., dev version)
    if ([[self currentInstalledVersion] compare:currentAppStoreVersion options:NSNumericSearch] == NSOrderedAscending) {
        return true;
    } else {
        return false;
    }
}

- (void)appStoreVersionIsNewer:(NSString *)currentAppStoreVersion {
    NSDictionary<NSString *, id> *results = [self.appData valueForKey:@"results"];
    self.appID = [results valueForKey:@"appID"];

    if (_appID == nil) {
        [self printDebugMessage:@"appID is nil, which means appID key is missing from the JSON results. Thanks!"];
    } else {
        [self localizeAlertStringsForCurrentAppStoreVersion:currentAppStoreVersion];
        [self alertTypeForVersion:currentAppStoreVersion];
        [self showAlertIfCurrentAppStoreVersionNotSkipped:currentAppStoreVersion];
    }
}

- (void)launchAppStore {
    NSString *iTunesString = [NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", [self appID]];
    NSURL *iTunesURL = [NSURL URLWithString:iTunesString];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:iTunesURL options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:iTunesURL];
        }
        
        if ([self.delegate respondsToSelector:@selector(SSForceUpdateUserDidLaunchAppStore)]){
            [self.delegate SSForceUpdateUserDidLaunchAppStore];
        }
    });
}

#pragma mark - Alert Management

- (void)showAlertIfCurrentAppStoreVersionNotSkipped:(NSString *)currentAppStoreVersion {
    // Check if user decided to skip this version in the past
    NSString *storedSkippedVersion = [[NSUserDefaults standardUserDefaults] objectForKey:SSForceUpdateDefaultSkippedVersion];
    
    if (![storedSkippedVersion isEqualToString:currentAppStoreVersion]) {
        [self showAlertWithAppStoreVersion:currentAppStoreVersion];
    } else {
        // Don't show alert.
        return;
    }
}

- (void)showAlertWithAppStoreVersion:(NSString *)currentAppStoreVersion {
    // Show Appropriate UIAlertView
    switch ([self alertType]) {
            
        case SSForceUpdateAlertTypeForce: {
            
            UIAlertController *alertController = [self createAlertController];
            [alertController addAction:[self updateAlertAction]];
            
            [self showAlertController:alertController];
            
        } break;
            
        case SSForceUpdateAlertTypeOption: {
            
            UIAlertController *alertController = [self createAlertController];
            
            if(self.notificationPeriodInDays)
                [alertController addAction:[self remindMeAfterCertainPeriodAction]];
            else
                [alertController addAction:[self nextTimeAlertAction]];
            
            [alertController addAction:[self updateAlertAction]];
            
            [self showAlertController:alertController];
            
        } break;
            
        case SSForceUpdateAlertTypeSkip: {
            
            UIAlertController *alertController = [self createAlertController];
            [alertController addAction:[self skipAlertAction]];
           // [alertController addAction:[self nextTimeAlertAction]];
            [alertController addAction:[self remindMeAfterCertainPeriodAction]];
            [alertController addAction:[self updateAlertAction]];
            
            [self showAlertController:alertController];
            
        } break;
            
        case SSForceUpdateAlertTypeNone: { //If the delegate is set, pass a localized update message. Otherwise, do nothing.
            if ([self.delegate respondsToSelector:@selector(SSForceUpdateDidDetectNewVersionWithoutAlert:)]) {
                [self.delegate SSForceUpdateDidDetectNewVersionWithoutAlert:_theNewVersionMessage];
            }
        } break;
    }
}

- (void)showAlertController:(UIAlertController *)alertController {
    
    if (_presentingViewController != nil) {
        [_presentingViewController presentViewController:alertController animated:YES completion:nil];
        
        if (_alertControllerTintColor) {
            [alertController.view setTintColor:_alertControllerTintColor];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(SSForceUpdateDidShowUpdateDialog)]){
        [self.delegate SSForceUpdateDidShowUpdateDialog];
    }
}

- (UIAlertController *)createAlertController {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:_updateAvailableMessage message:_theNewVersionMessage preferredStyle:UIAlertControllerStyleAlert];
    
    return alertController;
}

- (void)alertTypeForVersion:(NSString *)currentAppStoreVersion {
    // Check what version the update is, major, minor or a patch
    NSArray *oldVersionComponents = [[self currentInstalledVersion] componentsSeparatedByString:@"."];
    NSArray *newVersionComponents = [currentAppStoreVersion componentsSeparatedByString: @"."];
    
    BOOL oldVersionComponentIsProperFormat = (2 <= [oldVersionComponents count] && [oldVersionComponents count] <= 4);
    BOOL newVersionComponentIsProperFormat = (2 <= [newVersionComponents count] && [newVersionComponents count] <= 4);
    
    if (oldVersionComponentIsProperFormat && newVersionComponentIsProperFormat) {
        if ([newVersionComponents[0] integerValue] > [oldVersionComponents[0] integerValue]) { // A.b.c.d
            if (_majorUpdateAlertType) _alertType = _majorUpdateAlertType;
        } else if ([newVersionComponents[1] integerValue] > [oldVersionComponents[1] integerValue]) { // a.B.c.d
            if (_minorUpdateAlertType) _alertType = _minorUpdateAlertType;
        } else if ((newVersionComponents.count > 2) && (oldVersionComponents.count <= 2 || ([newVersionComponents[2] integerValue] > [oldVersionComponents[2] integerValue]))) { // a.b.C.d
            if (_patchUpdateAlertType) _alertType = _patchUpdateAlertType;
        } else if ((newVersionComponents.count > 3) && (oldVersionComponents.count <= 3 || ([newVersionComponents[3] integerValue] > [oldVersionComponents[3] integerValue]))) { // a.b.c.D
            if (_revisionUpdateAlertType) _alertType = _revisionUpdateAlertType;
        }
    }
}

- (void)localizeAlertStringsForCurrentAppStoreVersion:(NSString *)currentAppStoreVersion {
    // Reference App's name
    _appName = _appName ? _appName : [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    
    // Force localization if _forceLanguageLocalization is set
    if (_forceLanguageLocalization) {
        _updateAvailableMessage = [self forcedLocalizedStringForKey:@"Update Available"];
        _theNewVersionMessage = [NSString stringWithFormat:[self forcedLocalizedStringForKey:@"A new version of %@ is available. Please update to version %@ now."], _appName, currentAppStoreVersion];
        _updateButtonText = [self forcedLocalizedStringForKey:@"Update"];
        _nextTimeButtonText = [self forcedLocalizedStringForKey:@"Next time"];
        
      //  if(self.notificationPeriodInDays)
            _remindMeAfterCertainPeriodButtonText = [self forcedLocalizedStringForKey:[NSString stringWithFormat:@"Remind me after %ld days", (long)self.notificationPeriodInDays]];
//        else
//            _remindMeAfterCertainPeriodButtonText = [self forcedLocalizedStringForKey:@"Next time"];
        
        _skipButtonText = [self forcedLocalizedStringForKey:@"Skip this version"];
    } else {
        _updateAvailableMessage = [self localizedStringForKey:@"Update Available"];
        _theNewVersionMessage = [NSString stringWithFormat:[self localizedStringForKey:@"A new version of %@ is available. Please update to version %@ now."], _appName, currentAppStoreVersion];
        _updateButtonText = [self localizedStringForKey:@"Update"];
        _nextTimeButtonText = [self localizedStringForKey:@"Next time"];
      //  if(self.notificationPeriodInDays)
            _remindMeAfterCertainPeriodButtonText = [self localizedStringForKey:[NSString stringWithFormat:@"Remind me after %ld days", (long)self.notificationPeriodInDays]];
//        else
//            _remindMeAfterCertainPeriodButtonText = [self localizedStringForKey:@"Next time"];
        _skipButtonText = [self localizedStringForKey:@"Skip this version"];
    }
}

#pragma mark - NSBundle

- (NSString *)bundleID {
    return [NSBundle mainBundle].bundleIdentifier;
}

- (NSString *)bundlePath {
    return [[NSBundle bundleForClass:[self class]] pathForResource:@"SSForceUpdate" ofType:@"bundle"];
}

- (NSString *)localizedStringForKey:(NSString *)stringKey {
    return ([[NSBundle bundleForClass:[self class]] pathForResource:@"SSForceUpdate" ofType:@"bundle"] ? [[NSBundle bundleWithPath:[self bundlePath]] localizedStringForKey:stringKey value:stringKey table:@"SSForceUpdateLocalizable"] : stringKey);
}

- (NSString *)forcedLocalizedStringForKey:(NSString *)stringKey {
    NSString *path = [[NSBundle bundleWithPath:[self bundlePath]] pathForResource:[self forceLanguageLocalization] ofType:@"lproj"];
    return [[NSBundle bundleWithPath:path] localizedStringForKey:stringKey value:stringKey table:@"SSForceUpdateLocalizable"];
}

#pragma mark - NSDate

- (NSInteger)daysSinceDate:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:date toDate:[NSDate new] options:0];
    return components.day;
}

- (NSInteger)daysSinceDateString:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSDate *releaseDate = [dateFormatter dateFromString:dateString];
    return [self daysSinceDate:releaseDate];
}

#pragma mark - UIAlertActions

- (UIAlertAction *)updateAlertAction {
    UIAlertAction *updateAlertAction = [UIAlertAction actionWithTitle:_updateButtonText
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self launchAppStore];
                                                              }];
    
    return updateAlertAction;
}

- (UIAlertAction *)remindMeAfterCertainPeriodAction {
    UIAlertAction *remindMeAfterCertainPeriodAction = [UIAlertAction
                                                   actionWithTitle:_remindMeAfterCertainPeriodButtonText style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    
                                                                    // Store version comparison date
                                                                    self.lastVersionCheckPerformedOnDate = [NSDate date];
                                                                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:SSForceUpdateLastVersionCheckStoredDate];
                                                                    [[NSUserDefaults standardUserDefaults] synchronize];
                                                                    
                                                                    NSDictionary<NSString *, id> *results = [self.appData valueForKey:@"results"];
                                                                    
                                                                    /**
                                                                     Store notification period in days
                                                                     */
                                                                    
                                                                    if(![[results valueForKey:@"force"] integerValue]) {
                                                                        self.notificationPeriodInDays = [[results valueForKey:@"notificationPeriodInDays"] integerValue];
                                                                        
                                                                        if(self.notificationPeriodInDays) {
                                                                            [[NSUserDefaults standardUserDefaults] setObject:@(self.notificationPeriodInDays) forKey:SSForceUpdateNotificationPeriodInDays];
                                                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                                                            self.alertType = SSForceUpdateAlertTypeOption;
                                                                        } else {
                                                                            self.notificationPeriodInDays = 0;
                                                                            [[NSUserDefaults standardUserDefaults] setObject:@(self.notificationPeriodInDays) forKey:SSForceUpdateNotificationPeriodInDays];
                                                                            [[NSUserDefaults standardUserDefaults] synchronize];
                                                                            self.alertType = SSForceUpdateAlertTypeForce;
                                                                        }
                                                                    } else {
                                                                        self.notificationPeriodInDays = 0;
                                                                        
                                                                        [[NSUserDefaults standardUserDefaults] setObject:@(self.notificationPeriodInDays) forKey:SSForceUpdateNotificationPeriodInDays];
                                                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                                                        self.alertType = SSForceUpdateAlertTypeForce;
                                                                    }
                                                                    
                                                                    if([self.delegate respondsToSelector:@selector(SSForceUpdateUserDidCancel)]){

                                                                        [self.delegate SSForceUpdateUserDidCancel];
                                                                        
                                                                        
                                                                    }
                                                                }];
    
    return remindMeAfterCertainPeriodAction;
}


- (UIAlertAction *)nextTimeAlertAction {
    UIAlertAction *nextTimeAlertAction = [UIAlertAction actionWithTitle:_nextTimeButtonText
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction *action) {
                                                                    
                                                                    NSDictionary<NSString *, id> *results = [self.appData valueForKey:@"results"];
                                                                    
                                                                    /**
                                                                     Store notification period in days
                                                                     */

                                                                        self.notificationPeriodInDays = [[results valueForKey:@"notificationPeriodInDays"] integerValue];
                                                                        
                                                                        [[NSUserDefaults standardUserDefaults] setObject:@(self.notificationPeriodInDays) forKey:SSForceUpdateNotificationPeriodInDays];
                                                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                                                    
                                                                    if([self.delegate respondsToSelector:@selector(SSForceUpdateUserDidCancel)]){
                                                                        
                                                                        [self.delegate SSForceUpdateUserDidCancel];
                                                                        
                                                                        
                                                                    }
                                                                }];
    
    return nextTimeAlertAction;
}

- (UIAlertAction *)skipAlertAction {
    __typeof__(self) __weak weakSelf = self;
    
    UIAlertAction *skipAlertAction = [UIAlertAction actionWithTitle:_skipButtonText
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[NSUserDefaults standardUserDefaults] setObject:weakSelf.currentAppStoreVersion forKey:SSForceUpdateDefaultSkippedVersion];
                                                                [[NSUserDefaults standardUserDefaults] synchronize];
                                                                if([self.delegate respondsToSelector:@selector(SSForceUpdateUserDidSkipVersion)]){
                                                                    [self.delegate SSForceUpdateUserDidSkipVersion];
                                                                }
                                                            }];
    
    return skipAlertAction;
}


#pragma mark - Logging

- (void)printDebugMessage:(NSString * _Nonnull)message {
    
    if ([self isDebugEnabled]) {
        NSLog(@"[SSForceUpdate]: %@", message);
    }
    
}

@end

