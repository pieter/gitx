//
//  PBDetailController.h
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBHistorySearchMode.h"

@class PBViewController;
@class PBGitSidebarController;
@class PBGitCommitController;
@class PBGitHistoryController;
@class PBGitRepository;
@class RJModalRepoSheet;
@class PBGitRef;
@class PBGitRepositoryDocument;

@interface PBGitWindowController : NSWindowController<NSWindowDelegate> {
	__weak PBViewController *contentController;

	PBGitSidebarController *sidebarController;
	PBGitHistoryController *_historyViewController;
	PBGitCommitController *_commitViewController;

	__weak IBOutlet NSView *sourceListControlsView;
	__weak IBOutlet NSSplitView *splitView;
	__weak IBOutlet NSView *sourceSplitView;
	__weak IBOutlet NSView *contentSplitView;
	__weak IBOutlet NSSegmentedControl *segmentedControl;

	__weak IBOutlet NSTextField *statusField;
	__weak IBOutlet NSProgressIndicator *progressIndicator;
}

@property (nonatomic, strong) PBGitRepository *repository;
/* This is assign because that's what NSWindowController says :-S */
@property (assign) PBGitRepositoryDocument *document;
@property (readonly) PBGitHistoryController *historyViewController;
@property (readonly) PBGitCommitController *commitViewController;

- (instancetype)init;

- (void)changeContentController:(PBViewController *)controller;

- (void)showCommitHookFailedSheet:(NSString *)messageText infoText:(NSString *)infoText commitController:(PBGitCommitController *)controller;

- (void)showMessageSheet:(NSString *)messageText infoText:(NSString *)infoText;
- (void)showErrorSheet:(NSError *)error;


- (void)openURLs:(NSArray <NSURL *> *)fileURLs;
- (void)revealURLsInFinder:(NSArray <NSURL *> *)fileURLs;

- (IBAction) showCommitView:(id)sender;
- (IBAction) showHistoryView:(id)sender;
- (IBAction) revealInFinder:(id)sender;
- (IBAction) openInTerminal:(id)sender;
- (IBAction) refresh:(id)sender;

- (IBAction) showAddRemoteSheet:(id)sender;

- (IBAction) fetchRemote:(id)sender;
- (IBAction) fetchAllRemotes:(id)sender;

- (IBAction) pullRemote:(id)sender;
- (IBAction) pullRebaseRemote:(id)sender;
- (IBAction) pullDefaultRemote:(id)sender;
- (IBAction) pullRebaseDefaultRemote:(id)sender;

- (IBAction) stashSave:(id) sender;
- (IBAction) stashSaveWithKeepIndex:(id) sender;
- (IBAction) stashPop:(id) sender;

- (void)setHistorySearch:(NSString *)searchString mode:(PBHistorySearchMode)mode;

- (void)performFetchForRef:(PBGitRef *)ref;
- (void)performPullForBranch:(PBGitRef *)branchRef remote:(PBGitRef *)remoteRef rebase:(BOOL)rebase;
- (void)performPushForBranch:(PBGitRef *)branchRef toRemote:(PBGitRef *)remoteRef;

@end
