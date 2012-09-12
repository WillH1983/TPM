//
//  TPMTwitterTableViewController.m
//  TPM
//
//  Created by Will Hindenburg on 8/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TPMTwitterTableViewController.h"

@interface TPMTwitterTableViewController ()

@end

@implementation TPMTwitterTableViewController

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
    
    [[[self navigationController] navigationBar] setTintColor:[UIColor colorWithHue:0 saturation:0 brightness:0.30 alpha:1.0]];
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

@end
