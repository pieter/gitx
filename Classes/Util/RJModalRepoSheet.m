//
//  RJModalRepoSheet.m
//  GitX
//
//  Created by Rowan James on 1/7/12.
//  Copyright (c) 2012 Phere Development Pty. Ltd. All rights reserved.
//

#import "RJModalRepoSheet.h"

#import "PBGitRepository.h"
#import "PBGitWindowController.h"

@implementation RJModalRepoSheet

- (id) initWithWindowNibName:(NSString *)windowNibName forRepo:(PBGitRepository*)repo
{
	self = [super initWithWindowNibName:windowNibName];
	if (!self)
		return nil;

	self.repository = repo;
	self.windowController = repo.windowController;
	
	return self;
}

- (void) show
{
	[self.windowController showModalSheet:self];
}

- (void) hide
{
	[self.windowController hideModalSheet:self];
}

@end
