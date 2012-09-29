//
//  WordPressAPITableViewController.h
//  TPM
//
//  Created by William Hindenburg on 9/26/12.
//
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface WordPressAPITableViewController : UITableViewController <UISearchDisplayDelegate>

@property (nonatomic, strong) NSArray *articlesArray;
@property (nonatomic, strong) NSArray *searchResultsArray;
@property (nonatomic, strong) MBProgressHUD *searchActivityIndicator;

@end
