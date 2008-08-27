//
//  PBLine.m
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitGraphLine.h"


@implementation PBGitGraphLine
@synthesize upper, from, to;
- (id)initWithUpper: (int) u From: (int) f to: (int) t;
{
	upper = u;
	from = f;
	to = t;
	
	return self;
}

+ (PBGitGraphLine*) lowerLineFrom:(int) f to: (int) t
{
	return [[PBGitGraphLine alloc] initWithUpper:0 From:f to:t];
}

+ (PBGitGraphLine*) upperLineFrom:(int) f to: (int) t
{
	return [[PBGitGraphLine alloc] initWithUpper:1 From:f to:t];
}
@end
