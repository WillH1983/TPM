//
//  TPMAppDelegate.m
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TPMAppDelegate.h"
#import "NSMutableDictionary+appConfiguration.h"
#import "UAirship.h"

@implementation TPMAppDelegate

@synthesize window = _window;
@synthesize appConfiguration = _appConfiguration;
@synthesize facebookSession = _facebookSession;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.appConfiguration = [[NSMutableDictionary alloc] init];
    self.appConfiguration.RSSlink = [[NSURL alloc] initWithString:@"http://www.techpoweredmath.com/feed"];
    self.appConfiguration.defaultLocalPathImageForTableViewCell = @"TPM_Default_Cell_Image";
    self.appConfiguration.appName = @"Tech Powered Math";
    facebookSession = [[FBSession alloc] init];
    [FBSession setDefaultAppID:FACEBOOK_APP_ID];
    self.appConfiguration.facebookID = FACEBOOK_APP_ID;
    self.appConfiguration.facebookFeedToRequest = @"techpoweredmath";
    self.appConfiguration.twitterUserNameToRequest = @"techpoweredmath";
    self.appConfiguration.facebookCommentButtonImageTitle = @"FacebookButton";

    application.statusBarStyle = UIStatusBarStyleBlackOpaque;
    
    //Init Airship launch options
    NSMutableDictionary *takeOffOptions = [[NSMutableDictionary alloc] init];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please populate AirshipConfig.plist with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];
    
    // Register for notifications
    [[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert)];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.appConfiguration.appName message:[userInfo valueForKeyPath:@"aps.alert"] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    [alertView show];
    /*[[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
     [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
     [[UIApplication sharedApplication] cancelAllLocalNotifications];*/
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // this means the user switched back to this app without completing 
    // a login in Safari/Facebook App
    if (FBSession.activeSession.state == FBSessionStateCreatedOpening) {
        [FBSession.activeSession close]; // so we close our session and start over
    }
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [FBSession.activeSession close];
    
    [UAirship land];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Updates the device token and registers the token with UA
    [[UAirship shared] registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"%@", error);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.appConfiguration.appName message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    [alertView show];
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url]; 
}


-(BOOL)openURL:(NSURL *)url
{
    [[NSNotificationCenter defaultCenter] 
     postNotificationName:@"urlSelected"
     object:url];
    
    return YES;
}

@end
