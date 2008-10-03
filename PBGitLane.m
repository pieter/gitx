//
//  PBGitLane.m
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitLane.h"


@implementation PBGitLane

static int PBGITLANE_CURRENT_INDEX = 0;

@synthesize sha, index;

+ (void) resetColors
{
	PBGITLANE_CURRENT_INDEX = 0;
}

- (id) initWithCommit: (NSString*) c
{
	index = PBGITLANE_CURRENT_INDEX++;
	sha = c;
	
	return self;
}

- (BOOL) isCommit: (NSString*) s
{
	return [sha isEqualToString:s];
}
@end
