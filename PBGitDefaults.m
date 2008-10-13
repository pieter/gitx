//
//  PBGitDefaults.m
//  GitX
//
//  Created by Jeff Mesnil on 19/10/08.
//  Copyright 2008 Jeff Mesnil (http://jmesnil.net/). All rights reserved.
//

#import "PBGitDefaults.h"

#define kDefaultVerticalLineLength 50
#define kCommitMessageViewVerticalLineLength @"PBCommitMessageViewVerticalLineLength"

@implementation PBGitDefaults

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithInt:kDefaultVerticalLineLength]
                      forKey:kCommitMessageViewVerticalLineLength];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	NSLog(@"registered defaults: %@", defaultValues);
}

+ (int) commitMessageViewVerticalLineLength
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:kCommitMessageViewVerticalLineLength];
}

@end
