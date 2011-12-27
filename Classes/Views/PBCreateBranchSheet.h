//
//  PBCreateBranchSheet.h
//  GitX
//
//  Created by Nathan Kinsinger on 12/13/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRefish.h"


@class PBGitRepository;


@interface PBCreateBranchSheet : NSWindowController {
	PBGitRepository *repository;
	id <PBGitRefish> startRefish;

	BOOL shouldCheckoutBranch;

	NSTextField *branchNameField;
	NSTextField *errorMessageField;
}

+ (void) beginCreateBranchSheetAtRefish:(id <PBGitRefish>)ref inRepository:(PBGitRepository *)repo;


- (IBAction) createBranch:(id)sender;
- (IBAction) closeCreateBranchSheet:(id)sender;


@property  PBGitRepository *repository;
@property  id <PBGitRefish> startRefish;

@property (assign) BOOL shouldCheckoutBranch;

@property  IBOutlet NSTextField *branchNameField;
@property  IBOutlet NSTextField *errorMessageField;

@end
