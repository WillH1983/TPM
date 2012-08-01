//
//  NSString+Facebook.m
//  TPM
//
//  Created by Will Hindenburg on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+Facebook.h"
#import "FaceBookTableViewController.h"

@implementation NSString (Facebook)

- (CGSize)size
{
    CGSize maxSize = CGSizeMake(320 - FACEBOOK_FONT_SIZE, CGFLOAT_MAX);
    CGSize size = [self sizeWithFont:[UIFont systemFontOfSize:FACEBOOK_FONT_SIZE]  constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    size.height += FACEBOOK_TEXTVIEW_TOP_MARGIN;
    return size;
}

- (CGRect)buttonImageFrameForPhotoPost
{
    CGRect frame = CGRectMake(10, FACEBOOK_TEXTVIEW_POSITION_FROM_TOP + self.size.height + FACEBOOK_MARGIN_BETWEEN_COMMENTS_BUTTONS, FACEBOOK_PHOTO_WIDTH, FACEBOOK_PHOTO_HEIGHT);
    return frame;
}

- (CGRect)commentsButtonFrameForPhotoPost
{
    CGRect frame = CGRectMake(310 - FACEBOOK_COMMENTS_BUTTON_WIDTH, FACEBOOK_TEXTVIEW_POSITION_FROM_TOP + self.size.height + (FACEBOOK_MARGIN_BETWEEN_COMMENTS_BUTTONS * 2) + FACEBOOK_PHOTO_HEIGHT, FACEBOOK_COMMENTS_BUTTON_WIDTH, FACEBOOK_COMMENTS_BUTTON_HEIGHT);
    return frame;
}

- (CGRect)commentsButtonFrameForDefaultPost
{
    CGRect frame = CGRectMake(310 - FACEBOOK_COMMENTS_BUTTON_WIDTH, FACEBOOK_TEXTVIEW_POSITION_FROM_TOP + self.size.height + FACEBOOK_MARGIN_BETWEEN_COMMENTS_BUTTONS, FACEBOOK_COMMENTS_BUTTON_WIDTH, FACEBOOK_COMMENTS_BUTTON_HEIGHT);
    return frame;
}

- (CGRect)mainCommentsButtonFrameForPhotoPost
{
    CGRect frame = CGRectMake(15, self.commentsButtonFrameForPhotoPost.origin.y, 70, FACEBOOK_COMMENTS_BUTTON_HEIGHT);
    return frame;
}

- (CGRect)mainCommentsButtonFrameForDefaultPost
{
    CGRect frame = CGRectMake(15, self.commentsButtonFrameForDefaultPost.origin.y, 70, FACEBOOK_COMMENTS_BUTTON_HEIGHT);
    return frame;
}

@end
