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
    CGSize maxSize = CGSizeMake(self.frame.size.width - self.font.pointSize, CGFLOAT_MAX);
    CGSize size = [self.text sizeWithFont:self.font  constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    size.height += 12;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, size.height);
    
}

@end
