//
//  BaseRSSTableView.h
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseRSSTableView : UIViewController
@property (strong, nonatomic) NSURL *mainRSSLink;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
