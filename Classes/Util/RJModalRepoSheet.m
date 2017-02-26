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
#import "PBGitRepositoryDocument.h"

@implementation RJModalRepoSheet

@dynamic document;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName windowController:(nonnull PBGitWindowController *)windowController
{
	NSParameterAssert(windowController != nil);

	self = [super initWithWindowNibName:windowNibName owner:self];
	if (!self) return nil;

	_windowController = windowController;

	return self;
}

- (PBGitRepositoryDocument *)document {
	return self.windowController.document;
}

- (PBGitRepository *)repository
{
	return self.document.repository;
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
