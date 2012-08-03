//
//  TwitterTableViewController.m
//  TPM
//
//  Created by Will Hindenburg on 8/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitterTableViewController.h"
#import "UITextView+Facebook.h"
#import <Twitter/Twitter.h>

@interface TwitterTableViewController ()

@end

@implementation TwitterTableViewController
@synthesize twitterTableData = _twitterTableData;
@synthesize activityIndicator = _activityIndicator;

- (NSArray *)twitterTableData
{
    if (!_twitterTableData) _twitterTableData = [[NSArray alloc] init];
    return _twitterTableData;
}

- (void)setTwitterTableData:(NSArray *)twitterTableData
{
    _twitterTableData = twitterTableData;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    //  First, we create a dictionary to hold our request parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@"techpoweredmath" forKey:@"screen_name"];
    [params setObject:@"20" forKey:@"count"];
    [params setObject:@"1" forKey:@"include_entities"];
    [params setObject:@"1" forKey:@"include_rts"];
    
    //  Next, we create an URL that points to the target endpoint
    NSURL *url = 
    [NSURL URLWithString:@"http://api.twitter.com/1/statuses/user_timeline.json"];
    
    //  Now we can create our request.  Note that we are performing a GET request.
    TWRequest *request = [[TWRequest alloc] initWithURL:url 
                                             parameters:params 
                                          requestMethod:TWRequestMethodGET];
    
    //  Perform our request
    [request performRequestWithHandler:
     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
         
         if (responseData) {
             //  Use the NSJSONSerialization class to parse the returned JSON
             NSError *jsonError;
             NSArray *timeline = 
             [NSJSONSerialization JSONObjectWithData:responseData 
                                             options:NSJSONReadingMutableLeaves 
                                               error:&jsonError];
             
             if (timeline) {
                 // We have an object that we can parse
                 NSLog(@"%@", timeline);
                 if ([timeline isKindOfClass:[NSArray class]])
                 {
                     self.twitterTableData = timeline;
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self.activityIndicator stopAnimating];
                     });
                 }
             } 
             else { 
                 // Inspect the contents of jsonError
                 NSLog(@"%@", jsonError);
             }
         }
     }];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.twitterTableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"twitterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *postedBy = (UILabel *)[cell.contentView viewWithTag:2];
    UITextView *tweetText = (UITextView *)[cell.contentView viewWithTag:3];
    UILabel *twitterScreenName = (UILabel *)[cell.contentView viewWithTag:4];
    UILabel *postedDate = (UILabel *)[cell.contentView viewWithTag:5];
    
    NSDictionary *tweetDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    
    postedBy.text = [tweetDictionary valueForKeyPath:TWITTER_NAME];
    NSString *screeName = [tweetDictionary valueForKeyPath:TWITTER_SCREEN_NAME];
    twitterScreenName.text = [NSString stringWithFormat:@"@%@", screeName];
    
    tweetText.text = [tweetDictionary valueForKeyPath:TWITTER_TWEET];
    [tweetText resizeHeightBasedOnString];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE MMM d HH:mm:ss zzzz yyyy"];
    NSDate *date = [dateFormatter dateFromString:[tweetDictionary valueForKeyPath:TWITTER_POSTED_DATE]];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    postedDate.text = [dateFormatter stringFromDate:date];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"twitterCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UITextView *tweetText = (UITextView *)[cell.contentView viewWithTag:3];
    
    NSDictionary *tweetDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    
    CGFloat oldSizeHeight = tweetText.frame.size.height;
    tweetText.text = [tweetDictionary valueForKeyPath:TWITTER_TWEET];
    [tweetText resizeHeightBasedOnString];
    CGFloat heightChange = tweetText.frame.size.height - oldSizeHeight;
    CGFloat height = cell.frame.size.height + heightChange;
    
    return height;
}

- (void)tableView:(UITableView *)tableview willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *twitterDictionary = [self.twitterTableData objectAtIndex:indexPath.row];
    NSURL *profileImageURL = [NSURL URLWithString:[twitterDictionary valueForKeyPath:TWITTER_PROFILE_IMAGE]];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSData *picture = [NSData dataWithContentsOfURL:profileImageURL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *tmpArray = [self.tableView indexPathsForVisibleRows];
            if ([tmpArray containsObject:indexPath])
            {
                UITableViewCell *cell = [tableview cellForRowAtIndexPath:indexPath];
                UIImageView *profileImageVIew = (UIImageView *)[cell.contentView viewWithTag:1];
                profileImageVIew.image = [UIImage imageWithData:picture];
            }
        });
    });
}

@end
