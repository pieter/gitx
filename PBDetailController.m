//
//  PBDetailController.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBDetailController.h"


@implementation PBDetailController

@synthesize selectedTab, webCommit, rawCommit, realCommit, gitTree;

- init
{
	self.selectedTab = [NSNumber numberWithInt:0];
	[commitController bind:@"realCommit" toObject:self withKeyPath:@"selection" options:nil];
	return self;
}

- (void) updateKeys
{
	self.webCommit = nil;
	self.rawCommit = nil;
	self.gitTree = nil;
	
	int num = [self.selectedTab intValue];

	if (num == 0) // Detailed view
		self.webCommit = self.realCommit;
	if (num == 1)
		self.rawCommit = self.realCommit;
	if (num == 2)
		self.gitTree = self.realCommit.tree;
}	

- (void) setRealCommit: (PBGitCommit*) commit
{
	realCommit = commit;
	[self updateKeys];
}

- (void) setSelectedTab: (NSNumber*) number
{
	selectedTab = number;
	[self updateKeys];
}
@end
