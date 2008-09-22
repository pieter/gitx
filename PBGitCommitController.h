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
	NSArray *unstagedFiles;
	NSArray *cachedFiles;
}

@property (retain) NSArray *unstagedFiles, *cachedFiles;

- (void) readCachedFiles;
- (void) readUnstagedFiles;

@end
