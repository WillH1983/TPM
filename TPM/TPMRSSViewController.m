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

@end

@implementation TPMRSSViewController
@synthesize scrollView;
@synthesize pageControl;
@synthesize pageImages = _pageImages;
@synthesize pageViews = _pageViews;
@synthesize FeaturedStories = _FeaturedStories;
@synthesize featuredStoriesLabel = _featuredStoriesLabel;
@synthesize featureStoriesActivityIndicator = _featureStoriesActivityIndicator;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.featureStoriesActivityIndicator startAnimating];
    
    __block typeof(self) bself = self;
    [self setFinishblock:^{
        id tmpData = [self.RSSDataArray valueForKeyPath:@"category.text"];
        NSArray *categories = nil;
        if ([tmpData isKindOfClass:[NSArray class]]) categories = tmpData;
        for(int n = 0; n < [categories count] || n < 3; n++)
        {
            id items = [categories objectAtIndex:n];
            if ([items isKindOfClass:[NSArray class]])
            {
                for (NSString *category in items)
                {
                    if ([category isEqualToString:@"Featured"])
                    {
                        if ([self.FeaturedStories count] < 3)
                        {
                            [self.FeaturedStories addObject:[self.RSSDataArray objectAtIndex:n]];
                        }
                    }
                }
            }
        }
        [self.pageImages removeAllObjects];
       for (NSDictionary *dictionary in self.FeaturedStories)
       {
           NSString *content = [dictionary valueForKeyPath:@"content:encoded.text"];
           NSURL *url = content.imageFromHTMLString;
               NSData *picture = nil;
               if (url)
               {
                   picture = [NSData dataWithContentsOfURL:url];
                   UIImage *image = [UIImage imageWithData:picture];
                   [self.pageImages addObject:image];
               }
       }
        dispatch_async(dispatch_get_main_queue(), ^{
            [bself loadPageControls];
            [self.featureStoriesActivityIndicator stopAnimating];
        });
    }];
    
    self.scrollView.delegate = self;
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
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.pageImages.count, pagesScrollViewSize.height);
    
    // 5
    [self loadVisiblePages];
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setPageControl:nil];
    [self setFeaturedStoriesLabel:nil];
    [self setFeatureStoriesActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load the pages that are now on screen
    [self loadVisiblePages];
}

- (void)loadVisiblePages {
    // First, determine which page is currently visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    // Update the page control
    self.pageControl.currentPage = page;

    NSString *titleString = [[self.FeaturedStories objectAtIndex:page] valueForKeyPath:@"title.text"];
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
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
        // 3
        UIButton *buttonView = [UIButton buttonWithType:UIButtonTypeCustom];
        buttonView.frame = frame;
        buttonView.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *scaledImage = [self getScaledImage:[self.pageImages objectAtIndex:page] insideButton:buttonView];
        [buttonView setImage:scaledImage forState:UIControlStateNormal];
        [buttonView addTarget:self action:@selector(featuredStoriesSelected:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:buttonView];
        // 4
        [self.pageViews replaceObjectAtIndex:page withObject:buttonView];
    }
}

- (void)featuredStoriesSelected:(id)sender
{
    WebViewController *wvc = [[WebViewController alloc] init];
    NSURL *url = [[NSURL alloc] initWithString:[[self.FeaturedStories objectAtIndex:[self.pageControl currentPage]] valueForKeyPath:@"link.text"]];
    [wvc setUrlToLoad:url];
    [[self navigationController] pushViewController:wvc animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[[self navigationController] navigationBar] setTintColor:[UIColor colorWithHue:0 saturation:0 brightness:0.30 alpha:1.0]];

}

- (void)viewDidAppear:(BOOL)animated
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
