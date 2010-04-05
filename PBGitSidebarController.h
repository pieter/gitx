//
//  PBGitSidebar.h
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBViewController.h"

@class PBSourceViewItem;
@class PBGitHistoryController;
@class PBGitCommitController;
@class ApplicationController;

@interface PBGitSidebarController : PBViewController {
	IBOutlet NSWindow *window;
	IBOutlet NSOutlineView *sourceView;
	IBOutlet NSView *sourceListControlsView;
	IBOutlet NSPopUpButton *actionButton;

	NSMutableArray *items;

	/* Specific things */
	PBSourceViewItem *stage;

	PBSourceViewItem *branches, *remotes, *tags, *others;
    PBSourceViewItem * deferredSelectObject;

	PBGitHistoryController *historyViewController;
	PBGitCommitController *commitViewController;
}

- (void) selectStage;
- (void) selectBranch:(PBSourceViewItem *)branchItem;
- (void) selectCurrentBranch;

- (PBSourceViewItem *) selectedItem;

- (NSMenu *) menuForRow:(NSInteger)row;

@property(readonly) NSMutableArray *items;
@property(readonly) NSView *sourceListControlsView;
@property(readonly) PBSourceViewItem * remotes;
@property(readonly) NSOutlineView * sourceView;
@property(assign) PBSourceViewItem * deferredSelectObject;
@end
