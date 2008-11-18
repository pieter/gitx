//
//  PBGitCommitController.h
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBViewController.h"

@class PBIconAndTextCell;

@interface PBGitCommitController : PBViewController {
	NSMutableArray *files;
	
	IBOutlet NSTextView *commitMessageView;
	IBOutlet NSArrayController *unstagedFilesController;
	IBOutlet NSArrayController *cachedFilesController;

	IBOutlet id indexController;
	IBOutlet id webController;

	NSString *status;

	// We use busy as a count of active processes. 
	// You can increase it when your process start
	// And decrease it after you have finished.
	int busy;
	BOOL amend;

}

@property (retain) NSMutableArray *files;
@property (copy) NSString *status;
@property (assign) int busy;
@property (assign) BOOL amend;

- (void) readCachedFiles:(NSNotification *)notification;
- (void) readOtherFiles:(NSNotification *)notification;
- (void) readUnstagedFiles:(NSNotification *)notification;
- (void) stageHunk: (NSString *)hunk reverse:(BOOL)reverse;

- (IBAction) refresh:(id) sender;
- (IBAction) commit:(id) sender;
@end
