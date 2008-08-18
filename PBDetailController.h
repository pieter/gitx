//
//  PBDetailController.h
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBGitTree.h"

@interface PBDetailController : NSWindowController {
	IBOutlet NSNumber* selectedTab;
	IBOutlet NSArrayController* commitController;
	IBOutlet NSTreeController* treeController;
	IBOutlet NSOutlineView* fileBrowser;

	PBGitRepository* repository;
	PBGitTree* gitTree;
	PBGitCommit* webCommit;
	PBGitCommit* rawCommit;
	PBGitCommit* realCommit;
}

@property (copy) NSNumber* selectedTab;
@property (retain) PBGitRepository* repository;
@property (retain) PBGitCommit* webCommit;
@property (retain) PBGitCommit* rawCommit;
@property (retain) PBGitTree* gitTree;

- (id)initWithRepository:(PBGitRepository*)theRepository;

- (IBAction) setDetailedView: sender;
- (IBAction) setRawView: sender;
- (IBAction) setTreeView: sender;

- (IBAction) toggleQuickView: sender;
- (IBAction) openSelectedFile: sender;
- (void) updateQuicklookForce: (BOOL) force;

@end
