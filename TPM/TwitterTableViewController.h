//
//  TwitterTableViewController.h
//  TPM
//
//  Created by Will Hindenburg on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *twitterTableData;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

#define TWITTER_TWEET @"text"
#define TWITTER_NAME @"user.name"
#define TWITTER_PROFILE_IMAGE @"user.profile_image_url"
#define TWITTER_SCREEN_NAME @"user.screen_name"
#define TWITTER_POSTED_DATE @"created_at"

@end
