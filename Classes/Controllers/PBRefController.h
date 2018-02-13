//
//  PBRefController.h
//  GitX
//
//  Created by Pieter de Bie on 21-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitHistoryController.h"
#import "PBCommitList.h"
#import "PBGitRef.h"
#import "PBGitCommit.h"
#import "PBRefContextDelegate.h"

@class PBRefMenuItem;

@interface PBRefController : NSObject <PBRefContextDelegate> {
	__weak IBOutlet PBGitHistoryController *historyController;
	__weak IBOutlet NSArrayController *commitController;
	__weak IBOutlet PBCommitList *commitList;
}

- (IBAction) fetchRemote:(PBRefMenuItem *)sender;
- (IBAction) pullRemote:(PBRefMenuItem *)sender;
- (IBAction) pushUpdatesToRemote:(PBRefMenuItem *)sender;
- (IBAction) pushDefaultRemoteForRef:(PBRefMenuItem *)sender;
- (IBAction) pushToRemote:(PBRefMenuItem *)sender;
- (IBAction)showDeleteRefSheet:(PBRefMenuItem *)sender;

- (IBAction) checkout:(PBRefMenuItem *)sender;
- (IBAction) merge:(PBRefMenuItem *)sender;
- (IBAction) cherryPick:(PBRefMenuItem *)sender;
- (IBAction) rebaseHeadBranch:(PBRefMenuItem *)sender;
- (IBAction) copySHA:(PBRefMenuItem *)sender;
- (IBAction) copyShortSHA:(PBRefMenuItem *)sender;
- (IBAction) copyPatch:(PBRefMenuItem *)sender;
- (IBAction) diffWithHEAD:(PBRefMenuItem *)sender;
- (IBAction) showTagInfoSheet:(PBRefMenuItem *)sender;

@end
