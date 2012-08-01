//
//  NSString+Facebook.h
//  TPM
//
//  Created by Will Hindenburg on 7/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Facebook)
@property (nonatomic, readonly) CGRect buttonImageFrameForPhotoPost;
@property (nonatomic, readonly) CGRect commentsButtonFrameForPhotoPost;
@property (nonatomic, readonly) CGRect commentsButtonFrameForDefaultPost;
@property (nonatomic, readonly) CGRect mainCommentsButtonFrameForPhotoPost;
@property (nonatomic, readonly) CGRect mainCommentsButtonFrameForDefaultPost;
@property (nonatomic, readonly) CGSize size;
@end
