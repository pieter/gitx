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
	__weak PBGitRepository* repository;
	int selectedViewIndex;
	IBOutlet NSView* contentView;
	NSViewController* viewController;
}

@property (assign) __weak PBGitRepository *repository;
@property (readonly) NSViewController *viewController;
@property (assign) int selectedViewIndex;

- (id)initWithRepository:(PBGitRepository*)theRepository displayDefault:(BOOL)display;

- (void)changeViewController:(NSInteger)whichViewTag;
- (void)useToolbar:(NSToolbar *)toolbar;

- (IBAction) showCommitView:(id)sender;
- (IBAction) showHistoryView:(id)sender;
@end
