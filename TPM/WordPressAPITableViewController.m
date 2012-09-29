//
//  WordPressAPITableViewController.m
//  TPM
//
//  Created by William Hindenburg on 9/26/12.
//
//

#import "WordPressAPITableViewController.h"
#import "NSMutableDictionary+appConfiguration.h"
#import "TPMAppDelegate.h"
#import "WebViewController.h"
#import "NSString+HTML.h"

@interface WordPressAPITableViewController ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIBarButtonItem *oldBarButtonItem;
@end

@implementation WordPressAPITableViewController
@synthesize articlesArray = _articlesArray;
@synthesize activityIndicator = _activityIndicator;
@synthesize oldBarButtonItem = _oldBarButtonItem;

- (NSArray *)articlesArray
{
    if (!_articlesArray) _articlesArray = [[NSArray alloc] init];
    return _articlesArray;
}

- (void)setArticlesArray:(NSArray *)articlesArray
{
    _articlesArray = articlesArray;
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
    
    //initialize the activity indicator, set it to the center top of the view, and
    //start it animating
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicator.hidesWhenStopped = YES;
    
    [self.activityIndicator startAnimating];
    
    //Save the previous rightBarButtonItem so it can be put back on once the View is done loading
    self.oldBarButtonItem = self.navigationItem.rightBarButtonItem;
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    [self downloadData];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[[self navigationController] navigationBar] setTintColor:[UIColor colorWithHue:0 saturation:0 brightness:0.30 alpha:1.0]];
    
    //Set the Tech Powered Math logo to the title view of the navigation controler
    //With the content mode set to AspectFit
    UIImage *logoImage = [UIImage imageNamed:@"tpm-header.png"];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = logoImageView;
}

- (void)downloadData
{
    dispatch_queue_t downloadQueue = dispatch_queue_create("downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSString *query = @"http://www.techpoweredmath.com/api/get_recent_posts/?page=1&count=30";
        NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:query] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSMutableDictionary *jsonDictionary = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        self.articlesArray = [jsonDictionary valueForKey:@"posts"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.navigationItem.rightBarButtonItem = self.oldBarButtonItem;
        });
    });
                   
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return [self.articlesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Set the cell identifier to the same as the prototype cell in the story board
    static NSString *CellIdentifier = @"jsonAPICell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    //If there is no reusable cell of this type, create a new one
    if (!cell)
    {
        //Set the atributes of the main page cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
    }
    
    //Retrieve the corresponding dictionary to the index row requested
    id dictionaryForCell = [self.articlesArray objectAtIndex:[indexPath row]];
    NSString *mainTextLabel = nil;
    NSString *detailTextLabel = nil;
    
    if ([dictionaryForCell isKindOfClass:[NSDictionary class]])
    {
        //Pull the main and detail text label out of the corresponding dictionary
        mainTextLabel = [dictionaryForCell valueForKey:@"title"];
        mainTextLabel = [mainTextLabel stringByDecodingXMLEntities];
        
        detailTextLabel = [dictionaryForCell valueForKey:@"excerpt"];
        detailTextLabel = [detailTextLabel stringByDecodingXMLEntities];
    }
    
    
    //Check if the main text label is equal to NSNULL, if it is replace the text
    TPMAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if ([mainTextLabel isEqual:[NSNull null]]) mainTextLabel = appDelegate.appConfiguration.appName;
    
    //Set the cell text label's based upon the table contents array location
    cell.textLabel.text = mainTextLabel;
    cell.detailTextLabel.text = detailTextLabel;
    
    cell.imageView.image = [UIImage imageNamed:appDelegate.appConfiguration.defaultLocalPathImageForTableViewCell];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"webView" sender:[self.articlesArray objectAtIndex:indexPath.row]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"webView"])
    {
        [segue.destinationViewController setUrlToLoad:[NSURL URLWithString:[sender valueForKey:@"url"]]];
    }
}

- (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)tableView:(UITableView *)tableview willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block NSURL *url = nil;
    NSDictionary *RSSContentDictionary = [self.articlesArray objectAtIndex:indexPath.row];
    url = [NSURL URLWithString:[RSSContentDictionary valueForKey:@"thumbnail"]];
    dispatch_queue_t downloadQueue = dispatch_queue_create("Profile Image Downloader", NULL);
    dispatch_async(downloadQueue, ^{
        if (!url)
        {
            NSString *htmlString = [RSSContentDictionary valueForKeyPath:@"content"]; //fix me
            url = [htmlString imageFromHTMLString];
        }
        
        NSData *picture = nil;
        if (url)
        {
            picture = [NSData dataWithContentsOfURL:url];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *tmpArray = [self.tableView indexPathsForVisibleRows];
                if ([tmpArray containsObject:indexPath])
                {
                    UIImage *image = [UIImage imageWithData:picture];
                    UIImage *imageResized = [self imageWithImage:image scaledToSize:CGSizeMake(50, 50)];
                    cell.imageView.image = imageResized;
                    
                }
            });
        }
        
    });
    dispatch_release(downloadQueue);
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
