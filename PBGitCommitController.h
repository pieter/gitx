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
	
	IBOutlet NSArrayController *unstagedFilesController;
	IBOutlet NSArrayController *cachedFilesController;

	IBOutlet PBIconAndTextCell* unstagedButtonCell;
	IBOutlet PBIconAndTextCell* cachedButtonCell;
}

@property (retain) NSMutableArray *files;

- (void) readCachedFiles;
- (void) readOtherFiles;
- (void) readUnstagedFiles;

- (IBAction) refresh:(id) sender;
@end
