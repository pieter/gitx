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
	PBGitRepository* repository;
	int selectedViewIndex;
	IBOutlet NSView* contentView;
	NSViewController* viewController;
}

@property (retain) PBGitRepository *repository;
@property (readonly) NSViewController *viewController;
@property (assign) int selectedViewIndex;

- (id)initWithRepository:(PBGitRepository*)theRepository;

- (void)changeViewController:(NSInteger)whichViewTag;
- (void) focusOnSearchField;
@end
