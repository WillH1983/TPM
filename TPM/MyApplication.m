//
//  MyApplication.m
//  ImagoDei
//
//  Created by Will Hindenburg on 4/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyApplication.h"
#import "TPMAppDelegate.h"

@implementation MyApplication

- (BOOL)openURL:(NSURL *)url
{
    
    BOOL couldWeOpenUrl = NO;

    NSArray *urlComponenets = url.pathComponents;
    int oauthIndex = [urlComponenets indexOfObject:@"oauth"];
    NSString* scheme = [url.scheme lowercaseString];
    if([scheme compare:@"http"] == NSOrderedSame
       || [scheme compare:@"https"] == NSOrderedSame)
    {
        // TODO - Here you might also want to check for other conditions where you do not want your app opening URLs (e.g.
        // Facebook authentication requests, OAUTH requests, etc)
        
        // TODO - Update the cast below with the name of your AppDelegate
        // Let's call the method you wrote on your AppDelegate to actually open the BrowserViewController
        if (oauthIndex == NSNotFound)
        {
           couldWeOpenUrl = [(TPMAppDelegate *)self.delegate openURL:url]; 
        }
        
        
    }
    
    if(!couldWeOpenUrl)
    {
        return [super openURL:url];
    }
    else
    {
        return YES;
    }
}

@end
