//
//  PBDetailController.h
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRepository.h"

@class PBViewController, PBGitSidebarController, PBGitHistoryController;

@interface PBGitWindowController : NSWindowController {
	__weak PBGitRepository* repository;

	__weak PBViewController *contentController;
	__weak PBViewController* viewController;
	__weak PBGitSidebarController *sidebarController;
	__weak PBGitHistoryController *historyController;

	IBOutlet NSView *sourceListControlsView;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSView *sourceSplitView;
	IBOutlet NSView *contentSplitView;

	IBOutlet NSTextField *statusField;
	IBOutlet NSProgressIndicator *progressIndicator;

	IBOutlet NSToolbarItem *terminalItem;
	IBOutlet NSToolbarItem *finderItem;
}

@property (assign) __weak PBGitRepository *repository;
@property (assign) __weak PBViewController * viewController;
@property (assign) __weak PBViewController * contentController;
@property (assign) __weak PBGitSidebarController * sidebarController;
@property (assign) __weak PBGitHistoryController * historyController;

- (id)initWithRepository:(PBGitRepository*)theRepository displayDefault:(BOOL)display;

- (void)changeContentController:(PBViewController *)controller;

- (void)showMessageSheet:(NSString *)messageText infoText:(NSString *)infoText;
- (void)showErrorSheet:(NSError *)error;
- (void)showErrorSheetTitle:(NSString *)title message:(NSString *)message arguments:(NSArray *)arguments output:(NSString *)output;

- (IBAction) showCommitView:(id)sender;
- (IBAction) showHistoryView:(id)sender;
- (IBAction) revealInFinder:(id)sender;
- (IBAction) openInTerminal:(id)sender;
- (IBAction) cloneTo:(id)sender;
- (IBAction) refresh:(id)sender;
@end
