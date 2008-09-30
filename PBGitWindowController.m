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

- (id)initWithRepository:(PBGitRepository*)theRepository displayDefault:(BOOL)displayDefault
{
	if(self = [self initWithWindowNibName:@"RepositoryWindow"])
	{
		self.repository = theRepository;
		[self showWindow:nil];
	}
	
	if (displayDefault) {
		self.selectedViewIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"selectedViewIndex"];
	} else {
		self.selectedViewIndex = -1;
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
	[[NSUserDefaults standardUserDefaults] setInteger:i forKey:@"selectedViewIndex"];
	[self changeViewController: i];
}

- (void)changeViewController:(NSInteger)whichViewTag
{
	[self willChangeValueForKey:@"viewController"];
	self.searchController = nil;
	[self unbind:@"searchController"];
	if ([viewController view] != nil)
		[(PBViewController *)viewController removeView];
	
	switch (whichViewTag)
	{
		case 0:	// swap in the "CustomImageViewController - NSImageView"
			viewController = [[PBGitHistoryController alloc] initWithRepository:repository superController:self];
			[[self window] setToolbar:historyToolbar];
			break;
		case 1:
			viewController = [[PBGitCommitController alloc] initWithRepository:repository superController:self];
			[[self window] setToolbar:commitToolbar];
			break;
	}
	
	// make sure we automatically resize the controller's view to the current window size
	[[viewController view] setFrame: [contentView bounds]];
	
	//// embed the current view to our host view
	[contentView addSubview: [viewController view]];
	
	// Allow the viewcontroller to catch actions
	[self setNextResponder: viewController];
	if ([viewController respondsToSelector:@selector(commitController)])
		[self bind:@"searchController" toObject:viewController withKeyPath:@"commitController" options:nil];

		
	[self didChangeValueForKey:@"viewController"];	// this will trigger the NSTextField's value binding to change
}

- (void)awakeFromNib
{
	// We bind this ourselves because otherwise we would lose our selection
	[branchesController bind:@"selectionIndexes" toObject:repository withKeyPath:@"currentBranch" options:nil];

	[[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[[self window] setContentBorderThickness:35.0f forEdge:NSMinYEdge];
	[self showHistoryView:nil];

}

- (void) showCommitView:(id)sender
{
	self.selectedViewIndex = 1;
}

- (void) showHistoryView:(id)sender
{
	self.selectedViewIndex = 0;
}

@end
