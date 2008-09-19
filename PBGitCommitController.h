//
//  PBGitCommitController.h
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"
#import "PBGitWindowController.h"

@interface PBGitCommitController : NSViewController {
	PBGitRepository* repository;
	PBGitWindowController *superController;

}

@property (retain) PBGitRepository *repository;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller;

@end
