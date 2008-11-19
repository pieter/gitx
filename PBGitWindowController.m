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


@synthesize repository, viewController, selectedViewIndex;

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

- (void) setSelectedViewIndex: (int) i
{
	selectedViewIndex = i;
	[[NSUserDefaults standardUserDefaults] setInteger:i forKey:@"selectedViewIndex"];
	[self changeViewController: i];
}

- (void)changeViewController:(NSInteger)whichViewTag
{
	[self willChangeValueForKey:@"viewController"];

	if ([viewController view] != nil)
		[(PBViewController *)viewController removeView];

	switch (whichViewTag)
	{
		case 0:	// swap in the "CustomImageViewController - NSImageView"
			viewController = [[PBGitHistoryController alloc] initWithRepository:repository superController:self];
			break;
		case 1:
			viewController = [[PBGitCommitController alloc] initWithRepository:repository superController:self];
			break;
	}

	// make sure we automatically resize the controller's view to the current window size
	[[viewController view] setFrame: [contentView bounds]];
	
	//// embed the current view to our host view
	[contentView addSubview: [viewController view]];

	// Allow the viewcontroller to catch actions
	[self setNextResponder: viewController];
	[self didChangeValueForKey:@"viewController"];	// this will trigger the NSTextField's value binding to change
}

- (void)awakeFromNib
{
	[[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[[self window] setContentBorderThickness:35.0f forEdge:NSMinYEdge];
	[self showHistoryView:nil];
}

- (void) showCommitView:(id)sender
{
	if (self.selectedViewIndex != 1)
		self.selectedViewIndex = 1;
}

- (void) showHistoryView:(id)sender
{
	if (self.selectedViewIndex != 0)
		self.selectedViewIndex = 0;
}

#pragma mark -
#pragma mark Toolbar Delegates

- (void) useToolbar:(NSToolbar *)toolbar
{
	toolbar.displayMode = [self.window toolbar].displayMode;
	[toolbar setVisible: [[self.window toolbar] isVisible]];

	NSSegmentedControl *item = (NSSegmentedControl *)[[[toolbar items] objectAtIndex:0] view];
	[item bind:@"selectedIndex" toObject:self withKeyPath:@"selectedViewIndex" options:0];

	[self.window setToolbar:toolbar];
}

@end
