//
//  FaceBookTableViewController.m
//  TPM
//
//  Created by Will Hindenburg on 4/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FaceBookTableViewController.h"
#import "TPMAppDelegate.h"
#import "Facebook.h"
#import "WebViewController.h"
#import "ImageViewController.h"
#import "NSString+Facebook.h"

@interface FaceBookTableViewController ()
@property (nonatomic, strong) FBRequest *facebookRequest;
@property (nonatomic, strong) NSMutableDictionary *photoDictionary;

- (void)facebookInit;
@end

@implementation FaceBookTableViewController
@synthesize facebook = _facebook;
@synthesize facebookRequest = _facebookRequest;
@synthesize photoDictionary = _photoDictionary;
@synthesize facebookArrayTableData = _facebookArrayTableData;
@synthesize activityIndicator = _activityIndicator;
@synthesize oldBarButtonItem = _oldBarButtonItem;

- (NSMutableDictionary *)photoDictionary
{
    if (_photoDictionary == nil) _photoDictionary = [[NSMutableDictionary alloc] init];
    return _photoDictionary;
}

- (void)setFacebookArrayTableData:(NSArray *)facebookArrayTableData
{
    _facebookArrayTableData = facebookArrayTableData;
    [self.tableView reloadData];
}

- (NSArray *)facebookArrayTableData
{
    if (!_facebookArrayTableData) _facebookArrayTableData = [[NSArray alloc] init];
    return _facebookArrayTableData;
}

- (IBAction)LogOutInButtonClicked:(id)sender 
{
    UIBarButtonItem *barButton = nil;
    
    //Verify that object that was clicked was a UIBarButtonItem
    if ([sender isKindOfClass:[UIBarButtonItem class]])
    {
        //If it was, then assign barButton to sender
        barButton = sender;
    }
    //If not return without any action
    else return;
    
    //If the barbutton says Log Out, tell the facebook app to logout
    //and set the title of the button to Log In
    if ([barButton.title isEqualToString: @"Log Out"])
    {
        [self.facebook logout];
        barButton.title = @"Log In";
    }
    //If the barbutton says Log In, check if the facebook session is still valid
    else if ([barButton.title isEqualToString: @"Log In"])
    {
        //If it is not valid, reauthorize the app for single sign on
        if (![self.facebook isSessionValid]) 
        {
            [self.facebook authorize:[[NSArray alloc] initWithObjects:@"publish_stream", nil]];
        }
    }
}

#pragma mark - View Lifecycle

- (void)commonInit
{
    self.tabBarItem.title = @"Facebook";
    self.tableView.allowsSelection = NO;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self commonInit];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    //When the view disappears the code in this fucnction removes all delegation to this class
    //and it stops the loading
    
    //This is required incase a connection request is in progress when the view disappears
    [self.facebookRequest setDelegate:nil];
    
    //This is required incase a facebook method completes after the view has disappered
    TPMAppDelegate *appDelegate = (TPMAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.facebook.sessionDelegate = nil;
    
    //Super method
    [super viewDidDisappear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"urlSelected" object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //initialize the activity indicator, set it to the center top of the view, and
    //start it animating
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.activityIndicator.hidesWhenStopped = YES;
    
    //Save the previous rightBarButtonItem so it can be put back on once the View is done loading
    self.oldBarButtonItem = self.navigationItem.rightBarButtonItem;
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentWebView:) 
                                                 name:@"urlSelected"
                                               object:nil];
    
    if ([self.facebookArrayTableData count] > 0) return;
    
    //Init the facebook session
    [self facebookInit];
    
    //If the facebook session is already valid, the barButtonItem will be change to say "Log Out"
    if ([self.facebook isSessionValid]) 
    {
        self.navigationItem.leftBarButtonItem.title = @"Log Out";
    }
    
    //Help to verify small data requirement
    NSLog(@"Loading Web Data - Social Media View Controller");
    
    //Begin the facebook request, the data that comes back form this method will be used
    //to populate the UITableView
    [self.facebook requestWithGraphPath:FACEBOOK_FEED_TO_REQUEST andDelegate:self];
}

#pragma mark - Table view data source

- (NSString *)keyForMainCellLabelText
{
    return FACEBOOK_CONTENT_TITLE;
}

- (NSString *)keyForDetailCellLabelText
{
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.facebookArrayTableData count];
}

- (void)commentsButtonPushed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"detailView" sender:dictionaryData];
}

- (void)postImageButtonPressed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"Photo" sender:[dictionaryData valueForKeyPath:@"object_id"]];
}

- (void)mainCommentsButtonPushed:(id)sender
{
    UIView *contentView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary *dictionaryData = [self.facebookArrayTableData objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"textInput" sender:dictionaryData];
}

- (void)textView:(UITextView *)sender didFinishWithString:(NSString *)string withDictionaryForComment:(NSDictionary *)dictionary;
{
    NSString *graphAPIString = [NSString stringWithFormat:@"%@/comments", [dictionary valueForKeyPath:@"id"]];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:string, @"message", nil];
    
    [self.facebook requestWithGraphPath:graphAPIString andParams:params andHttpMethod:@"POST" andDelegate:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Set the cell identifier to the same as the prototype cell in the story board
    static NSString *CellIdentifier = @"Facebook Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITextView *textView = nil;
    UIButton *commentsButton = nil;
    UIButton *buttonImage = nil;
    UIImageView *profileImageView = nil;
    UILabel *postedByLabel = nil;
    UIButton *mainCommentButton = nil;
    
    //If there is no reusable cell of this type, create a new one
    if (!cell)
    {
        //Set the atributes of the main page cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        
        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        textView.font = [UIFont systemFontOfSize:FACEBOOK_FONT_SIZE];
        textView.scrollEnabled = NO;
        textView.editable = NO;
        textView.tag = 1;
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView.backgroundColor = [UIColor clearColor];
        textView.frame = CGRectMake(0, FACEBOOK_TEXTVIEW_POSITION_FROM_TOP, 320, 0);
        [cell.contentView addSubview:textView];
        
        commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        commentsButton.frame = CGRectMake(0, 0,FACEBOOK_COMMENTS_BUTTON_WIDTH, FACEBOOK_COMMENTS_BUTTON_HEIGHT);
        commentsButton.backgroundColor = [UIColor clearColor];
        commentsButton.titleLabel.font = [UIFont systemFontOfSize:FACEBOOK_COMMENTS_BUTTON_FONT_SIZE];
        commentsButton.tag = 2;
        [commentsButton addTarget:self action:@selector(commentsButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        commentsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        commentsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 5);
        UIImage *commentsButtonImage = [UIImage imageNamed:@"FacebookButton.png"];
        UIEdgeInsets commentsButtonImageEdge = UIEdgeInsetsMake(12, 12, 12, 12);
        UIImage *stretchableCommentsButtonImage = [commentsButtonImage resizableImageWithCapInsets:commentsButtonImageEdge];
        [commentsButton setBackgroundImage:stretchableCommentsButtonImage forState:UIControlStateNormal];
        [cell.contentView addSubview:commentsButton];
        
        buttonImage = [[UIButton alloc] initWithFrame:CGRectZero];
        [buttonImage addTarget:self action:@selector(postImageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        buttonImage.tag = 3;
        [cell.contentView addSubview:buttonImage];
        
        profileImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 40, 40)];
        profileImageView.tag = 4;
        [cell.contentView addSubview:profileImageView];
        
        postedByLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 5, 250, 20)];
        postedByLabel.backgroundColor = [UIColor clearColor];
        postedByLabel.font = [UIFont boldSystemFontOfSize:FACEBOOK_FONT_SIZE];
        postedByLabel.tag = 5;
        [cell.contentView addSubview:postedByLabel];
        
        mainCommentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        mainCommentButton.backgroundColor = [UIColor clearColor];
        mainCommentButton.titleLabel.font = [UIFont systemFontOfSize:FACEBOOK_COMMENTS_BUTTON_FONT_SIZE];
        mainCommentButton.tag = 6;
        [mainCommentButton addTarget:self action:@selector(mainCommentsButtonPushed:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:mainCommentButton];
        
    }
    else 
    {
        textView = (UITextView *)[cell.contentView viewWithTag:1];
        commentsButton = (UIButton *)[cell.contentView viewWithTag:2];
        buttonImage = (UIButton *)[cell.contentView viewWithTag:3];
        profileImageView = (UIImageView *)[cell.contentView viewWithTag:4];
        postedByLabel = (UILabel *)[cell.contentView viewWithTag:5];
        mainCommentButton = (UIButton *)[cell.contentView viewWithTag:6];
    }
    
    [buttonImage setBackgroundImage:nil forState:UIControlStateNormal];
    profileImageView.image = [UIImage imageWithCIImage:[CIImage emptyImage]];
    
    //Retrieve the corresponding dictionary to the index row requested
    NSDictionary *dictionaryForCell = [self.facebookArrayTableData objectAtIndex:[indexPath row]];
    
    NSString *typeOfPost = [dictionaryForCell valueForKeyPath:@"type"];
    
    //Pull the main and detail text label out of the corresponding dictionary
    NSString *mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForMainCellLabelText]];
    
    if (mainTextLabel == nil)
    {
        mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForDetailCellLabelText]];
    }
    
    if ([typeOfPost isEqualToString:@"link"])
    {
        NSRange range = [mainTextLabel rangeOfString:@"http"];
        if (range.location == NSNotFound)
        {
            NSString *linkURL = [dictionaryForCell valueForKeyPath:@"link"];
            if ([linkURL isKindOfClass:[NSString class]])
            {
                mainTextLabel = [mainTextLabel stringByAppendingString:@" "];
                mainTextLabel = [mainTextLabel stringByAppendingString:linkURL];
            }
        }
    }
    
    id fromName = [dictionaryForCell valueForKeyPath:@"from.name"];
    if ([fromName isKindOfClass:[NSString class]]) postedByLabel.text = fromName;
    
    //Set the cell text label's based upon the table contents array location
    textView.text = mainTextLabel;
    
    textView.frame = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, mainTextLabel.size.height);
    NSNumber *count = [dictionaryForCell valueForKeyPath:@"comments.count"];
    
    
    if ([typeOfPost isEqualToString:@"photo"])
    {
        buttonImage.frame = mainTextLabel.buttonImageFrameForPhotoPost;
        [buttonImage setImage:[UIImage imageWithCIImage:[CIImage emptyImage]] forState:UIControlStateNormal];
        commentsButton.frame = mainTextLabel.commentsButtonFrameForPhotoPost;
        NSString *commentsString = [[NSString alloc] initWithFormat:@"%@ Comments", count];
        [commentsButton setTitle:commentsString forState:UIControlStateNormal];
        
        mainCommentButton.frame = mainTextLabel.mainCommentsButtonFrameForPhotoPost;
        [mainCommentButton setTitle:@"Comment" forState:UIControlStateNormal];
    }
    else
    {
        buttonImage.frame = CGRectZero;
        commentsButton.frame = mainTextLabel.commentsButtonFrameForDefaultPost;
        NSString *commentsString = [[NSString alloc] initWithFormat:@"%@ Comments", count];
        [commentsButton setTitle:commentsString forState:UIControlStateNormal];
        
        mainCommentButton.frame = mainTextLabel.mainCommentsButtonFrameForDefaultPost;
        [mainCommentButton setTitle:@"Comment" forState:UIControlStateNormal];
        [mainCommentButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    }
    return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableview willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tmpDictionary = [self.facebookArrayTableData objectAtIndex:[indexPath row]];
    NSString *pictureID = [tmpDictionary valueForKeyPath:@"object_id"];
    NSString *profileFromId = [tmpDictionary valueForKeyPath:@"from.id"];
    
    //if (![type isEqualToString:@"photo"]) return;
    
    __block NSData *picture = [self.photoDictionary objectForKey:pictureID];
    __block NSData *profilePictureData = [self.photoDictionary objectForKey:profileFromId];
    
    NSString *urlStringForProfilePicture = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture/type=small", profileFromId];
    NSString *urlStringForPicture = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture?type=album", pictureID];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
    dispatch_async(downloadQueue, ^{
        
        if (!picture)
        {
            if (pictureID)
            {
                NSURL *url = [[NSURL alloc] initWithString:urlStringForPicture];
                picture = [NSData dataWithContentsOfURL:url];
                if (picture) [self.photoDictionary setObject:picture forKey:pictureID];
                NSLog(@"Picture");
            }
        }
        
        if (!profilePictureData)
        {
            if (profileFromId)
            {
                NSURL *profileUrl = [[NSURL alloc] initWithString:urlStringForProfilePicture];
                profilePictureData = [NSData dataWithContentsOfURL:profileUrl];
                if (profilePictureData) [self.photoDictionary setObject:profilePictureData forKey:profileFromId];
                NSLog(@"Profile Picture");
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *tmpArray = [self.tableView indexPathsForVisibleRows];
            if ([tmpArray containsObject:indexPath])
            {
                UIButton *buttonImage = (UIButton *)[cell.contentView viewWithTag:3];
                UIImage *image = [UIImage imageWithData:picture];
                [buttonImage setBackgroundImage:image forState:UIControlStateNormal];
                
                UIImageView *profileImageView = (UIImageView *)[cell.contentView viewWithTag:4];
                [profileImageView setImage:[UIImage imageWithData:profilePictureData]];
            }
        });
    });
    dispatch_release(downloadQueue);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Retrieve the corresponding dictionary to the index row requested
    NSDictionary *dictionaryForCell = [self.facebookArrayTableData objectAtIndex:[indexPath row]];
    
    //Pull the main and detail text label out of the corresponding dictionary
    NSString *mainTextLabel = [dictionaryForCell valueForKey:[self keyForMainCellLabelText]];
    
    NSString *typeOfPost = [dictionaryForCell valueForKeyPath:@"type"];
    
    if (mainTextLabel == nil)
    {
        mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForDetailCellLabelText]];
    }
    
    if ([typeOfPost isEqualToString:@"link"])
    {
        NSRange range = [mainTextLabel rangeOfString:@"http"];
        if (range.location == NSNotFound)
        {
            NSString *linkURL = [dictionaryForCell valueForKeyPath:@"link"];
            if ([linkURL isKindOfClass:[NSString class]])
            {
                mainTextLabel = [mainTextLabel stringByAppendingString:@" "];
                mainTextLabel = [mainTextLabel stringByAppendingString:linkURL];
            }
        }
    }
    
    CGSize stringSize = CGSizeZero;
    
    if ([typeOfPost isEqualToString:@"photo"])
    {
        stringSize.height = mainTextLabel.mainCommentsButtonFrameForPhotoPost.origin.y + mainTextLabel.commentsButtonFrameForPhotoPost.size.height;
    }
    else
    {
        stringSize.height = mainTextLabel.mainCommentsButtonFrameForDefaultPost.origin.y + mainTextLabel.mainCommentsButtonFrameForPhotoPost.size.height;
    }
    return stringSize.height + FACEBOOK_TEXTVIEW_TOP_MARGIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"Cell Push" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Web"] & [sender isKindOfClass:[NSURL class]])
    {
        [segue.destinationViewController setUrlToLoad:sender];
    }
    else if ([segue.identifier isEqualToString:@"detailView"])
    {
        if ([sender isKindOfClass:[NSDictionary class]])
        {
            //Set the model for the MVC we are about to push onto the stack
            [segue.destinationViewController setShortCommentsDictionaryModel:sender];
            
            //Set the delegate of the social media detail controller to this class
            [segue.destinationViewController setSocialMediaDelegate:self];
        }
    }
    else if ([segue.identifier isEqualToString:@"Photo"])
    {
        if ([sender isKindOfClass:[NSString class]])
        {
            [segue.destinationViewController setFacebookPhotoObjectID:sender];
        }
    }
    else if ([segue.identifier isEqualToString:@"textInput"])
    {
        [segue.destinationViewController setTextEntryDelegate:self];
        [segue.destinationViewController setDictionaryForComment:sender];
    }
}

#pragma mark - SocialMediaDetailView datasource

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender dictionaryForFacebookGraphAPIString:(NSString *)facebookGraphAPIString
{
    NSLog(@"Loading Web Data - Social Media View Controller");
    
    //When the SocialMediaDetailViewController needs further information from
    //the facebook class, this method is called
    [self.facebook requestWithGraphPath:facebookGraphAPIString andDelegate:sender];
}

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender postDataForFacebookGraphAPIString:(NSString *)facebookGraphAPIString withParameters:(NSMutableDictionary *)params
{
    [self.facebook requestWithGraphPath:facebookGraphAPIString andParams:params andHttpMethod:@"POST" andDelegate:sender];
}

#pragma mark - Facebook Initialization Method

- (void)facebookInit
{
    //Retrieve a pointer to the appDelegate
    TPMAppDelegate *appDelegate = (TPMAppDelegate *)[[UIApplication sharedApplication] delegate];

    //Set the local facebook property to point to the appDelegate facebook property
    self.facebook = appDelegate.facebook;
    NSLog(@"%@", self.facebook);
    
    //Set the facebook session delegate to this class
    self.facebook.sessionDelegate = self;
    
    //Retrieve the user defaults and store them in a variable
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //If the User defaults contain the facebook access tokens, save them into the
    //facebook instance
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) 
    {
        self.facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        self.facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
}

#pragma mark - Facebook Dialog Methods

- (IBAction)postToWall:(id)sender 
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   FACEBOOK_APP_ID, @"app_id",
                                   @"Post to Imago Dei's Wall", @"description",
                                   @"imagodeichurch", @"to",
                                   nil];
    
    [self.facebook dialog:@"feed" andParams:params andDelegate:self];
}

#pragma mark - Facebook Request Delegate Methods

- (void)requestLoading:(FBRequest *)request
{
    //When a facebook request starts, save the request
    //so the delegate can be set to nill when the view disappears
    self.facebookRequest = request;
    
    [self.activityIndicator startAnimating];
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Since the request has been recieved, and parsed, stop the Activity Indicator
        [self.activityIndicator stopAnimating];
        self.facebookArrayTableData = nil;
        [self.tableView reloadData];
        //[self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
        NSDictionary *errorDictionary = [error userInfo];
        NSString *errorMessage = [errorDictionary valueForKeyPath:@"error.message"];
        NSNumber *errorCode = [errorDictionary valueForKeyPath:@"error.code"];
        NSString *tmpString = nil;
        if ([errorCode intValue] == 104) tmpString = @"Please Log In to continue";
        else tmpString = errorMessage;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ImagoDei - Facebook" message:tmpString delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    });
    
}

- (void)request:(FBRequest *)request didLoad:(id)result
{
    //Since the facebook request is complete, and setting the delegate to nil
    //will not be required if the view disappears, set the request to nil
    self.facebookRequest = nil;
    
    if ([request.httpMethod isEqualToString:@"GET"])
    {
        //Verify the result from the facebook class is actually a dictionary
        if ([result isKindOfClass:[NSDictionary class]])
        {
            
            NSMutableArray *array = [result mutableArrayValueForKey:@"data"];
            
            //Set the property equal to the new comments array, which will then trigger a table reload
            self.facebookArrayTableData = array;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //Since the request has been recieved, and parsed, stop the Activity Indicator
            [self.activityIndicator stopAnimating];
            
            //If an oldbutton was removed from the right bar button spot, put it back
            self.navigationItem.rightBarButtonItem = self.oldBarButtonItem;
            
            //[self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
        });
    }
    else {
        [self.facebook requestWithGraphPath:FACEBOOK_FEED_TO_REQUEST andDelegate:self];
    }
    
}


#pragma mark - Facebook Session Delegate Methods

- (void)fbDidLogin 
{
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    
    //Retireve the User Defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //Pull the accessToken, and expirationDate from the facebook instance, and
    //save them to the user defaults
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
    //Retrieve the left bar button item, and change the text to "Log Out"
    self.navigationItem.leftBarButtonItem.title = @"Log Out";
    
    //This method will request the full comments array from the delegate and
    //the facebook class will call request:request didLoad:result when complete
    [self.facebook requestWithGraphPath:FACEBOOK_FEED_TO_REQUEST andDelegate:self];
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    //Do nothing here for now, stubbed out to get rid of compiler warning
    NSLog(@"I FAILED");
}

- (void) fbDidLogout 
{
    // Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt
{
    //Retrieve the user defaults, and save the new tokens
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

- (void)fbSessionInvalidated
{
    //Do nothing here for now, stubbed out to get rid of compiler warning
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)refresh {
    //This method will request the full comments array from the delegate and
    //the facebook class will call request:request didLoad:result when complete
    [self.facebook requestWithGraphPath:FACEBOOK_FEED_TO_REQUEST andDelegate:self];
}

- (void) presentWebView:(NSNotification *) notification
{
    
    if ([[notification name] isEqualToString:@"urlSelected"])
    {
        NSLog(@"%@", [notification object]);
        [self performSegueWithIdentifier:@"Web" sender:[notification object]];
    }
}

@end