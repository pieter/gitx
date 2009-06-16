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

@interface PBGitHistoryController : PBViewController {
	IBOutlet NSSearchField *searchField;
	IBOutlet NSArrayController* commitController;
	IBOutlet NSTreeController* treeController;
	IBOutlet NSOutlineView* fileBrowser;
	IBOutlet NSTableView* commitList;

	IBOutlet id webView;
	int selectedTab;
	
	PBGitTree* gitTree;
	PBGitCommit* webCommit;
	PBGitCommit* rawCommit;
	PBGitCommit* realCommit;
}

@property (assign) int selectedTab;
@property (retain) PBGitCommit *webCommit, *rawCommit;
@property (retain) PBGitTree* gitTree;
@property (readonly) NSArrayController *commitController;

- (IBAction) setDetailedView: sender;
- (IBAction) setRawView: sender;
- (IBAction) setTreeView: sender;

- (void) selectCommit: (NSString*) commit;
- (IBAction) refresh: sender;
- (IBAction) toggleQuickView: sender;
- (IBAction) openSelectedFile: sender;
- (void) updateQuicklookForce: (BOOL) force;

// Context menu methods
- (NSMenu *)contextMenuForTreeView;
- (NSArray *)menuItemsForPaths:(NSArray *)paths;
- (void)showCommitsFromTree:(id)sender;
- (void)showInFinderAction:(id)sender;

- (void) copyCommitInfo;

- (BOOL) hasNonlinearPath;

- (NSMenu *)tableColumnMenu;
@end
