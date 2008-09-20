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
#import "PBGitRepository.h"
#import "PBGitWindowController.h"

@interface PBGitHistoryController : NSViewController {
	PBGitRepository* repository;
	PBGitWindowController *superController;

	IBOutlet NSArrayController* commitController;
	IBOutlet NSTreeController* treeController;
	IBOutlet NSOutlineView* fileBrowser;
	IBOutlet NSTableView* commitList;	
	int selectedTab;
	
	PBGitTree* gitTree;
	PBGitCommit* webCommit;
	PBGitCommit* rawCommit;
	PBGitCommit* realCommit;
	
}

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller;

@property (assign) int selectedTab;
@property (retain) PBGitCommit *webCommit, *rawCommit;
@property (retain) PBGitRepository *repository;
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

@end
