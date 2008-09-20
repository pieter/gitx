//
//  PBDetailController.h
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"

@interface PBGitWindowController : NSWindowController {
	IBOutlet NSSearchField* searchField;
	IBOutlet NSArrayController* searchController;
	PBGitRepository* repository;
	IBOutlet NSView* contentView;
	NSViewController* viewController;
}

@property (retain) PBGitRepository *repository;
@property (readonly) NSViewController *viewController;
@property (retain) NSArrayController *searchController;

- (id)initWithRepository:(PBGitRepository*)theRepository;
- (void) focusOnSearchField;
@end
