//
//  PBGitHistoryView.h
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitCommit.h"
#import "PBGitTree.h"
#import "PBViewController.h"
#import "PBCollapsibleSplitView.h"
#import <Quartz/Quartz.h> /* for the QLPreviewPanelDataSource et al. stuff */

@class PBQLOutlineView;
@class PBGitSidebarController;
@class PBGitGradientBarView;
@class PBRefController;
@class QLPreviewPanel;

@interface PBGitHistoryController : PBViewController <QLPreviewPanelDataSource, QLPreviewPanelDelegate> {
	IBOutlet PBRefController *refController;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSArrayController* commitController;
	IBOutlet NSTreeController* treeController;
	IBOutlet NSOutlineView* fileBrowser;
	NSArray *currentFileBrowserSelectionPath;
	IBOutlet NSTableView* commitList;
	IBOutlet PBCollapsibleSplitView *historySplitView;
    QLPreviewPanel* previewPanel;

	IBOutlet PBGitGradientBarView *upperToolbarView;
	IBOutlet NSButton *mergeButton;
	IBOutlet NSButton *cherryPickButton;
	IBOutlet NSButton *rebaseButton;

	IBOutlet PBGitGradientBarView *scopeBarView;
	IBOutlet NSButton *allBranchesFilterItem;
	IBOutlet NSButton *localRemoteBranchesFilterItem;
	IBOutlet NSButton *selectedBranchFilterItem;

	IBOutlet id webView;
	int selectedCommitDetailsIndex;
	BOOL forceSelectionUpdate;
	
	PBGitTree *gitTree;
	PBGitCommit *webCommit;
	PBGitCommit *selectedCommit;
}

@property (assign) int selectedCommitDetailsIndex;
@property (retain) PBGitCommit *webCommit;
@property (retain) PBGitTree* gitTree;
@property (readonly) NSArrayController *commitController;
@property (readonly) PBRefController *refController;

- (IBAction) setDetailedView:(id)sender;
- (IBAction) setTreeView:(id)sender;
- (IBAction) setBranchFilter:(id)sender;

- (void) selectCommit: (NSString*) commit;
- (IBAction) refresh: sender;
- (IBAction) toggleQLPreviewPanel:(id)sender;
- (IBAction) openSelectedFile: sender;
- (void) updateQuicklookForce: (BOOL) force;

// Context menu methods
- (NSMenu *)contextMenuForTreeView;
- (NSArray *)menuItemsForPaths:(NSArray *)paths;
- (void)showCommitsFromTree:(id)sender;
- (void)showInFinderAction:(id)sender;
- (void)openFilesAction:(id)sender;

// Repository Methods
- (IBAction) createBranch:(id)sender;
- (IBAction) createTag:(id)sender;
- (IBAction) showAddRemoteSheet:(id)sender;
- (IBAction) merge:(id)sender;
- (IBAction) cherryPick:(id)sender;
- (IBAction) rebase:(id)sender;

- (void) copyCommitInfo;

- (BOOL) hasNonlinearPath;

- (NSMenu *)tableColumnMenu;

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview;
- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex;
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset;
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset;

@end
