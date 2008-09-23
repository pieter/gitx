//
//  PBGitCommitController.h
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBViewController.h"

@interface PBGitCommitController : PBViewController {
	NSMutableArray *files;
	
	IBOutlet NSArrayController *unstagedFilesController;
	IBOutlet NSArrayController *cachedFilesController;

	IBOutlet NSButtonCell* unstagedButtonCell;
	IBOutlet NSButtonCell* cachedButtonCell;
}

@property (retain) NSMutableArray *files;

- (void) readCachedFiles;
- (void) readOtherFiles;
- (void) readUnstagedFiles;

@end
