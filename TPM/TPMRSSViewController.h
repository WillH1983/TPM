//
//  TPMRSSViewController.h
//  TPM
//
//  Created by Will Hindenburg on 7/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseRSSTableView.h"

@interface TPMRSSViewController : BaseRSSTableView <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) NSMutableArray *pageImages;
@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, strong) NSMutableArray *FeaturedStories;
@property (weak, nonatomic) IBOutlet UILabel *featuredStoriesLabel;

- (void)loadVisiblePages;
- (void)loadPage:(NSInteger)page;
- (void)purgePage:(NSInteger)page;
@end
