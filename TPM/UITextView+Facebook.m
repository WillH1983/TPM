//
//  UITextView+Facebook.m
//  TPM
//
//  Created by Will Hindenburg on 8/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UITextView+Facebook.h"

@implementation UITextView (Facebook)

- (void)resizeHeightBasedOnString
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    CGFloat flexableWidth = CGFLOAT_MIN;
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft)
    {
        flexableWidth = 420;
    }
    else 
    {
        flexableWidth = 287;
    }
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, flexableWidth, self.frame.size.height);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.contentSize.height);
    
    
}

@end
