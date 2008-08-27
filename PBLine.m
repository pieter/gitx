//
//  PBLine.m
//  GitX
//
//  Created by Pieter de Bie on 27-08-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBLine.h"


@implementation PBLine
@synthesize upper, from, to;
- (id)initWithUpper: (int) u From: (int) f to: (int) t;
{
	upper = u;
	from = f;
	to = t;
	
	return self;
}

+ (PBLine*) lowerLineFrom:(int) f to: (int) t
{
	return [[PBLine alloc] initWithUpper:0 From:f to:t];
}

+ (PBLine*) upperLineFrom:(int) f to: (int) t
{
	return [[PBLine alloc] initWithUpper:1 From:f to:t];
}
@end
