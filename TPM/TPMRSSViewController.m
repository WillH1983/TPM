//
//  TPMRSSViewController.m
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TPMRSSViewController.h"
#import "NSString+HTML.h"

@interface TPMRSSViewController ()

@end

@implementation TPMRSSViewController
@synthesize scrollView;
@synthesize pageControl;
@synthesize pageImages = _pageImages;
@synthesize pageViews = _pageViews;
@synthesize FeaturedStories = _FeaturedStories;

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
        });
        
        NSLog(@"%@", self.FeaturedStories);
        NSLog(@"%d", [self.FeaturedStories count]);
    }];
    
    self.scrollView.delegate = self;
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
        UIImageView *newPageView = [[UIImageView alloc] initWithImage:[self.pageImages objectAtIndex:page]];
        newPageView.contentMode = UIViewContentModeScaleAspectFit;
        newPageView.frame = frame;
        [self.scrollView addSubview:newPageView];
        // 4
        [self.pageViews replaceObjectAtIndex:page withObject:newPageView];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}

- (void)viewDidAppear:(BOOL)animated
{
    [self loadVisiblePages];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
