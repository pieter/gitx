//
//  PBViewController.h
//  GitX
//
//  Created by Pieter de Bie on 22-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"
#import "PBGitWindowController.h"

@interface PBViewController : NSViewController {
	PBGitRepository *repository;
	PBGitWindowController *superController;
}

@property (readonly) PBGitRepository *repository;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller;

@end
