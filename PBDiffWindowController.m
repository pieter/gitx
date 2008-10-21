//
//  PBDiffWindowController.m
//  GitX
//
//  Created by Pieter de Bie on 13-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBDiffWindowController.h"


@implementation PBDiffWindowController
@synthesize diff;

- (id) initWithDiff:(NSString *)aDiff
{
	if (![super initWithWindowNibName:@"PBDiffWindow"])
		return nil;

	diff = aDiff;
	return self;
}

@end
