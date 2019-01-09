//
//  AppDelegate.m
//  DashControl
//
//  Created by Sam Westrich on 8/3/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "AppDelegate.h"

#import <CoreSpotlight/CoreSpotlight.h>
#import <UserNotifications/UserNotifications.h>

#import <DashSync/DashSync.h>
#import <SDWebImage/SDImageCache.h>

#ifdef DEBUG
#import <SimulatorStatusMagic/SDStatusBarManager.h>
#endif /* DEBUG */

#import "APITrigger.h"
#import "DCPersistenceStack.h"
#import "DCWalletManager.h"
#import "Injections.h"
#import "PortfolioViewController.h"
#import "UITestingHelper.h"

static NSUInteger const PORTFOLIO_TAB_INDEX = 3;

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate

+ (instancetype)sharedDelegate {
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // place all initialization code here that needs to be called "before" state restoration occurs
    //

    // At launch time, the system automatically loads your app’s main storyboard file and
    // loads the initial view controller. For apps that support state restoration, the state
    // restoration machinery restores your interface to its previous state between calls to the
    // application:willFinishLaunchingWithOptions: and application:didFinishLaunchingWithOptions: methods.
    // Use the application:willFinishLaunchingWithOptions: method to show your app window and to determine
    // if state restoration should happen at all. Use the application:didFinishLaunchingWithOptions: method
    // to make any final adjustments to your app’s user interface.

    // require the window being visible before state restoration
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    // DI
    [Injections activate];

    // CoreData stack
    [self.stack loadStack:^(DCPersistenceStack *_Nonnull stack) {
        [Injections activateCoreDataDependentInjections];
    }];

    // UI Testing
    if ([UITestingHelper isUITest]) {
        [UIView setAnimationsEnabled:NO];
#ifdef DEBUG
        [[SDStatusBarManager sharedInstance] enableOverrides];
#endif /* DEBUG */
    }

    // Request Device Token For Apple Push Notifications without auth request
    [self requestPushToken];

    [self configureAppearance];
    [self configureImageCache];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self.stack saveViewContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self.stack saveViewContext];
}

#pragma mark - NSUserActivity Search API

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)activity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    BOOL wasHandled = NO;
    if ([activity.activityType isEqual:CSSearchableItemActionType]) {
        NSString *activityIdentifier = [activity.userInfo valueForKey:CSSearchableItemActivityIdentifier];

        wasHandled = YES;

        // TODO: rewrite core spotlight support

        NSArray *identifierComponents = [activityIdentifier componentsSeparatedByString:@"/"];
        if ([identifierComponents.firstObject isEqualToString:@"post"]) {

            //            activityIdentifier = [activityIdentifier stringByReplacingOccurrencesOfString:@"post/" withString:@""];
            //
            //            UITabBarController *tabBarController = (UITabBarController *)_window.rootViewController;
            //            [tabBarController setSelectedIndex:kRSSFeedViewControllerIndex];
            //            UINavigationController *RSSFeedNavigationController = (UINavigationController*)[tabBarController.viewControllers objectAtIndex:kRSSFeedViewControllerIndex];
            //            [RSSFeedNavigationController dismissViewControllerAnimated:NO completion:nil];
            //            [RSSFeedNavigationController popToRootViewControllerAnimated:NO];
            //            RSSFeedListViewController *vc = (RSSFeedListViewController*)[[RSSFeedNavigationController viewControllers] firstObject];
            //            [vc simulateNavitationToPostWithGUID:activityIdentifier];
        }
        else if ([identifierComponents.firstObject isEqualToString:@"proposal"]) {

            //            activityIdentifier = [activityIdentifier stringByReplacingOccurrencesOfString:@"proposal/" withString:@""];
            //
            //            UITabBarController *tabBarController = (UITabBarController *)_window.rootViewController;
            //            [tabBarController setSelectedIndex:kProposalsViewControllerIndex];
            //            UINavigationController *proposalsNavigationController = (UINavigationController*)[tabBarController.viewControllers objectAtIndex:kProposalsViewControllerIndex];
            //            [proposalsNavigationController dismissViewControllerAnimated:NO completion:nil];
            //            [proposalsNavigationController popToRootViewControllerAnimated:NO];
            //            OldProposalsViewController *vc = (OldProposalsViewController*)[[proposalsNavigationController viewControllers] firstObject];
            //            [vc simulateNavitationToProposalWithHash:activityIdentifier];
        }
        else {
            wasHandled = NO;
        }
    }
    else {

        //the app was launched via Handoff protocol
        //or with a Universal Link
    }

    return wasHandled;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    DCLog([self class], @"PTKN: %@", token); // log even in release!
    [self.apiTrigger performRegisterWithDeviceToken:token];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    DCDebugLog(self.class, error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    // Handle silent push here

    completionHandler(UIBackgroundFetchResultNewData);
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if (![url.scheme isEqual:@"dashcontrol"]) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"Not a dash URL"
                             message:url.absoluteString
                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okButton = [UIAlertAction
            actionWithTitle:NSLocalizedString(@"ok", nil)
                      style:UIAlertActionStyleCancel
                    handler:^(UIAlertAction *action){
                    }];

        [alert addAction:okButton];
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];

        return NO;
    }

    NSArray *parameters = [url.host componentsSeparatedByString:@"&"];
    NSMutableDictionary *paramDictionary = [[NSMutableDictionary alloc] init];
    for (NSString *param in parameters) {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        if (keyValue.count == 2) {
            paramDictionary[keyValue.firstObject] = [keyValue.lastObject stringByRemovingPercentEncoding];
        }
    }
    if (paramDictionary[@"callback"]) {
        if ([[paramDictionary[@"callback"] lowercaseString] isEqualToString:@"masterpublickey"]) {
            NSString *extended32PublicKey = paramDictionary[@"masterPublicKeyBIP32"];
            NSString *extended44PublicKey = paramDictionary[@"masterPublicKeyBIP44"];
            [self.walletManager importWalletMasterAddressFromSource:@"Dashwallet"
                                            withExtended32PublicKey:extended32PublicKey
                                                extended44PublicKey:extended44PublicKey];
        }
    }

    return YES;
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSLog(@"User Info : %@", response.notification.request.content.userInfo);

    completionHandler();
}

#pragma mark - Notifications

- (void)requestPushToken {
    UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    [[UIApplication sharedApplication] registerForRemoteNotifications];

// simulate receiving token on simulator
#ifdef DEBUG
#if TARGET_OS_SIMULATOR
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"DEBUG_SIMULATED_PUSH_TOKEN"];
        if (!token) {
            token = [NSUUID UUID].UUIDString;
            [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"DEBUG_SIMULATED_PUSH_TOKEN"];
        }

        [self.apiTrigger performRegisterWithDeviceToken:token];
    });
#endif /* TARGET_OS_SIMULATOR */
#endif /* DEBUG */
}

- (void)registerForRemoteNotifications {
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError *_Nullable error) {
        DCDebugLog([self class], @"Push auth error: %@", error);
    }];
}

#pragma mark - Public

- (void)showAddMasternodeController {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    if (![tabBarController isKindOfClass:UITabBarController.class]) {
        NSAssert(NO, @"Invalid UI stack");
        return;
    }
    
    tabBarController.selectedIndex = PORTFOLIO_TAB_INDEX;
    
    UINavigationController *navigationController = (UINavigationController *)tabBarController.viewControllers[PORTFOLIO_TAB_INDEX];
    if (![navigationController isKindOfClass:UINavigationController.class]) {
        NSAssert(NO, @"Invalid UI stack");
        return;
    }
    
    [navigationController dismissViewControllerAnimated:NO completion:nil];
    [navigationController popToRootViewControllerAnimated:NO];
    
    PortfolioViewController *portfolioController = (PortfolioViewController *)navigationController.topViewController;
    if (![portfolioController isKindOfClass:PortfolioViewController.class]) {
        NSAssert(NO, @"Invalid UI stack");
        return;
    }
    
    [portfolioController showAddMasternodeController];
}

#pragma mark - Private

- (void)configureAppearance {
    [[UITabBarItem appearance] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"Montserrat-SemiBold" size:10.0] }
                                             forState:UIControlStateNormal];
}

- (void)configureImageCache {
    SDImageCacheConfig *config = [SDImageCache sharedImageCache].config;
    config.maxCacheAge = 60 * 60 * 24 * 28;  // 4 weeks
    config.maxCacheSize = 1024 * 1204 * 200; // 200 mb
}

@end
