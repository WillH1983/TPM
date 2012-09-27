//
//  TPMRSSViewController.m
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TPMRSSViewController.h"
#import "NSString+HTML.h"
#import "WebViewController.h"

@interface TPMRSSViewController ()
@property (nonatomic) CGRect tableViewFrameAtStartup;
@end

@implementation TPMRSSViewController
@synthesize pagingScrollView;
@synthesize pageControl;
@synthesize pageImages = _pageImages;
@synthesize pageViews = _pageViews;
@synthesize FeaturedStories = _FeaturedStories;
@synthesize featuredStoriesLabel = _featuredStoriesLabel;
@synthesize featureStoriesActivityIndicator = _featureStoriesActivityIndicator;
@synthesize tableViewFrameAtStartup;

- (NSMutableArray *)FeaturedStories
{
    if (!_FeaturedStories) _FeaturedStories = [[NSMutableArray alloc] init];
    return _FeaturedStories;
}

- (NSMutableArray *)pageImages
{
    if (!_pageImages) _pageImages = [[NSMutableArray alloc] init];
    return _pageImages;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //Setup the tabbar with the background image, selected image
    self.tabBarController.tabBar.backgroundImage = [UIImage imageNamed:@"TabbarImage.png"];
    self.tabBarController.tabBar.selectionIndicatorImage = [UIImage imageNamed:@"tabbar-active-bg"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.featureStoriesActivityIndicator startAnimating];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSString *query = @"http://www.techpoweredmath.com/api/get_category_posts/?slug=featured&count=3";
        NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:query] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSMutableDictionary *jsonDictionary = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        self.FeaturedStories = [jsonDictionary valueForKey:@"posts"];
        [self.pageImages removeAllObjects];
        for (NSDictionary *dictionary in self.FeaturedStories)
        {
            NSURL *url = nil;
            id images = [dictionary valueForKeyPath:@"images.full"];
            if (images)
            {
                if ([images isKindOfClass:[NSArray class]])
                {
                    url = [NSURL URLWithString:[[images valueForKey:@"url"] objectAtIndex:0]];
                }
                else
                {
                    url = [NSURL URLWithString:[images valueForKey:@"url"]];
                }
            }
            NSString *content = [dictionary valueForKeyPath:@"content"];
            if (!url) url = content.imageFromHTMLString;
            NSData *picture = nil;
            UIImage *image = nil;
            if (url)
            {
                picture = [NSData dataWithContentsOfURL:url];
                image = [UIImage imageWithData:picture];
            }
            else
            {
                image = [UIImage imageNamed:@"TPM_Default_Cell_Image@2x.png"];
            }
            [self.pageImages addObject:image];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadPageControls];
            [self.featureStoriesActivityIndicator stopAnimating];
        });
    });

    
    self.tableViewFrameAtStartup = self.tableView.frame;
    
    self.pagingScrollView.delegate = self;
    self.featuredStoriesLabel.userInteractionEnabled = NO;
    [self.pageControl addTarget:self action:@selector(pageControlChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)pageControlChanged:(id)sender
{
    //This doesn't do anything for now
    
    [self loadVisiblePages];
}

- (void)loadPageControls
{
    
    NSInteger pageCount = self.pageImages.count;
    
    // 2
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = pageCount;
    
    // 3
    self.pageViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < pageCount; ++i) {
        [self.pageViews addObject:[NSNull null]];
    }
    
    // 4
    CGSize pagesScrollViewSize = self.pagingScrollView.frame.size;
    self.pagingScrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.pageImages.count, pagesScrollViewSize.height);
    
    // 5
    [self loadVisiblePages];
}

- (void)viewDidUnload
{
    [self setPagingScrollView:nil];
    [self setPageControl:nil];
    [self setFeaturedStoriesLabel:nil];
    [self setFeatureStoriesActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load the pages that are now on screen
    BOOL test = scrollView.pagingEnabled;
    if (test) [self loadVisiblePages];
}

- (void)loadVisiblePages {
    // First, determine which page is currently visible
    CGFloat pageWidth = self.pagingScrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.pagingScrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    // Update the page control
    self.pageControl.currentPage = page;

    NSString *titleString = [[self.FeaturedStories objectAtIndex:page] valueForKeyPath:@"title"];
    self.featuredStoriesLabel.text = titleString;
    // Work out which pages you want to load
    NSInteger firstPage = page - 1;
    NSInteger lastPage = page + 1;
    
    // Purge anything before the first page
    for (NSInteger i=0; i<firstPage; i++) {
        [self purgePage:i];
    }
    
	// Load pages in our range
    for (NSInteger i=firstPage; i<=lastPage; i++) {
        [self loadPage:i];
    }
    
	// Purge anything after the last page
    for (NSInteger i=lastPage+1; i<self.pageImages.count; i++) {
        [self purgePage:i];
    }
}

- (void)purgePage:(NSInteger)page {
    if (page < 0 || page >= self.pageImages.count) {
        // If it's outside the range of what you have to display, then do nothing
        return;
    }
    
    // Remove a page from the scroll view and reset the container array
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView != [NSNull null]) {
        [pageView removeFromSuperview];
        [self.pageViews replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}

- (UIImage *) getScaledImage:(UIImage *)img insideButton:(UIButton *)btn 
{
    
    // Check which dimension (width or height) to pay respect to and
    // calculate the scale factor
    CGFloat imgRatio = img.size.width / img.size.height,
    btnRatio = btn.frame.size.width / btn.frame.size.height,
    scaleFactor = (imgRatio > btnRatio
                   ? img.size.width / btn.frame.size.width
                   : img.size.height / btn.frame.size.height);
                   
                   // Create image using scale factor
    UIImage *scaledImg = [UIImage imageWithCGImage:[img CGImage] 
                                             scale:scaleFactor 
                                       orientation:UIImageOrientationUp];
    return scaledImg;
}

- (void)loadPage:(NSInteger)page {
    if (page < 0 || page >= self.pageImages.count) {
        // If it's outside the range of what you have to display, then do nothing
        return;
    }
    
    // 1
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView == [NSNull null]) {
        // 2
        CGRect frame = self.pagingScrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
        // 3
        UIButton *buttonView = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonView.frame = frame;
        buttonView.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *scaledImage = [self getScaledImage:[self.pageImages objectAtIndex:page] insideButton:buttonView];
        [buttonView setImage:scaledImage forState:UIControlStateNormal];
        [buttonView addTarget:self action:@selector(featuredStoriesSelected:) forControlEvents:UIControlEventTouchUpInside];
        [self.pagingScrollView addSubview:buttonView];
        // 4
        [self.pageViews replaceObjectAtIndex:page withObject:buttonView];
    }
}

- (void)featuredStoriesSelected:(id)sender
{
    WebViewController *wvc = [[WebViewController alloc] init];
    NSURL *url = [[NSURL alloc] initWithString:[[self.FeaturedStories objectAtIndex:[self.pageControl currentPage]] valueForKeyPath:@"url"]];
    [wvc setUrlToLoad:url];
    [[self navigationController] pushViewController:wvc animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Set the Tech Powered Math logo to the title view of the navigation controler
    //With the content mode set to AspectFit
    UIImage *logoImage = [UIImage imageNamed:@"tpm-header.png"];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = logoImageView;
    
    UIColor *background = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"black_textured_background_seamless.jpg"]];
    self.pagingScrollView.backgroundColor = background;
    
    [[[self navigationController] navigationBar] setTintColor:[UIColor colorWithHue:0 saturation:0 brightness:0.30 alpha:1.0]];
    
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //[self.pageViews removeAllObjects];
    NSArray *views = [self.pagingScrollView subviews];
    for (id view in views) [view removeFromSuperview];
    [self loadPageControls];
    UIView *pageView = [self.pageViews objectAtIndex: [self.pageControl currentPage]];
    CGRect pageRect = pageView.frame;
    self.pagingScrollView.contentOffset = CGPointMake(pageRect.origin.x, pageRect.origin.y);
}

@end
