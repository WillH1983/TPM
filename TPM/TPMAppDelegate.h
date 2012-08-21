//
//  TPMAppDelegate.h
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "NSMutableDictionary+appConfiguration.h"

#define FACEBOOK_APP_ID @"268933006548697"

@interface TPMAppDelegate : UIResponder <UIApplicationDelegate>
{
    FBSession *facebookSession;
}
    
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSMutableDictionary *appConfiguration;
@property (strong, nonatomic) FBSession *facebookSession;

- (BOOL)openURL:(NSURL *)url;

@end
