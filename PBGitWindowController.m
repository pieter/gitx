//
//  PBDetailController.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitWindowController.h"
#import "PBGitHistoryController.h"
#import "PBGitCommitController.h"


@implementation PBGitWindowController


@synthesize repository, viewController, searchController, selectedViewIndex;

- (id)initWithRepository:(PBGitRepository*)theRepository;
{
	if(self = [self initWithWindowNibName:@"RepositoryWindow"])
	{
		self.repository = theRepository;
		[self showWindow:nil];
	}
	return self;
}

- (void) focusOnSearchField
{
	[[self window] makeFirstResponder:searchField];
}

- (void) setSelectedViewIndex: (int) i
{
	selectedViewIndex = i;
	[self changeViewController: i];
}

- (void)changeViewController:(NSInteger)whichViewTag
{
	[self willChangeValueForKey:@"viewController"];
	
	if ([viewController view] != nil)
		[[viewController view] removeFromSuperview];	// remove the current view
	
	switch (whichViewTag)
	{
		case 0:	// swap in the "CustomImageViewController - NSImageView"
			viewController = [[PBGitHistoryController alloc] initWithRepository:repository superController:self];
			break;
		case 1:
			viewController = [[PBGitCommitController alloc] initWithRepository:repository superController:self];
	}
	

	
	//// embed the current view to our host view
	[contentView addSubview: [viewController view]];
	
	[self bind:@"searchController" toObject:viewController withKeyPath:@"commitController" options:nil];
	
	// make sure we automatically resize the controller's view to the current window size
	[[viewController view] setFrame: [contentView bounds]];
		
	[self didChangeValueForKey:@"viewController"];	// this will trigger the NSTextField's value binding to change
}

- (void)awakeFromNib
{
	[self changeViewController:0];
}

@end
