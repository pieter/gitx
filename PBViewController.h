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
	__weak PBGitRepository *repository;
	__weak PBGitWindowController *superController;

	IBOutlet NSToolbar *viewToolbar;
}

@property (readonly) __weak PBGitRepository *repository;
@property (readonly) NSToolbar *viewToolbar;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller;

/* removeView is called whenever the view is removed, either to be swapped
 * with a different view, or when the repository window will be destroyed
 */
- (void) removeView;

/* Updateview is called every time it is loaded into the main view */
- (void) updateView;

/* Called after awakeFromNib:, and the view has been loaded into the main view.
 * Useful for resizing stuff after everything has been set in the right position
 */
- (void)viewLoaded;

- (NSResponder *)firstResponder;

@end
