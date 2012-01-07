//
//  RJModalRepoSheet.m
//  GitX
//
//  Created by Rowan James on 1/7/12.
//  Copyright (c) 2012 Phere Development Pty. Ltd. All rights reserved.
//

#import "RJModalRepoSheet.h"

#import "PBGitWindowController.h"

@implementation RJModalRepoSheet

@synthesize repoWindow;

- (id) initWithWindowNibName:(NSString *)windowNibName inRepoWindow:(PBGitWindowController *)parent
{
	self = [super initWithWindowNibName:windowNibName];
	if (!self)
		return nil;
	
	self.repoWindow = parent;
	
	return self;
}

- (void) show
{
	[repoWindow showModalSheet:self];
}

- (void) hide
{
	[repoWindow hideModalSheet:self];
}

@end
