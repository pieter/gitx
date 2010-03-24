//
//  PBLabelController.h
//  GitX
//
//  Created by Pieter de Bie on 21-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitHistoryController.h"
#import "PBCommitList.h"
#import "PBGitRef.h"
#import "PBGitCommit.h"
#import "PBRefContextDelegate.h"

@class KBPopUpToolbarItem;
@class PBRefMenuItem;

@interface PBRefController : NSObject <PBRefContextDelegate> {
	IBOutlet __weak PBGitHistoryController *historyController;
	IBOutlet NSArrayController *commitController;
	IBOutlet PBCommitList *commitList;

// <<<<<<< HEAD
//  IBOutlet NSWindow *newBranchSheet;
//  IBOutlet NSTextField *newBranchName;
//  IBOutlet NSTextField *errorMessage;
//     
//  IBOutlet NSWindow *addRemoteSheet;
//  IBOutlet NSTextField *addRemoteName;
//  IBOutlet NSTextField *addRemoteURL;
//  IBOutlet NSTextField *addRemoteErrorMessage;    
// 
//  IBOutlet NSWindow *newTagSheet;
//  IBOutlet NSTextField *newTagName;
//     IBOutlet NSTextView *newTagMessage;
//  IBOutlet NSTextField *newTagErrorMessage;
//  IBOutlet NSTextField *newTagCommit;
//  IBOutlet NSTextField *newTagSHA;
//  IBOutlet NSTextField *newTagSHALabel;
// 
// =======
// >>>>>>> 096a176fbd169d7d93ebf71c3ec605bb6cabd366
	IBOutlet NSPopUpButton *branchPopUp;
    IBOutlet KBPopUpToolbarItem *pullItem;
    IBOutlet KBPopUpToolbarItem *pushItem;
    IBOutlet KBPopUpToolbarItem *rebaseItem;
}

// <<<<<<< HEAD
// - (IBAction)addRef:(id)sender;
// - (IBAction)closeSheet:(id) sender;
// - (IBAction)saveSheet:(id) sender;
// 
// - (IBAction)rebaseButton:(id)sender;
// - (IBAction)pushButton:(id)sender;
// - (IBAction)pullButton:(id)sender;
// - (IBAction)fetchButton:(id)sender;
// 
// - (IBAction)addRemoteButton:(id)sender;
// - (IBAction)addRemoteSheet:(id)sender;
// - (IBAction)closeAddRemoteSheet:(id)sender;
// 
// - (IBAction)newTagButton:(id)sender;
// - (IBAction)newTagSheet:(id)sender;
// - (IBAction)closeNewTagSheet:(id)sender;
// 
// - (NSArray *) menuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit;
// 
// - (void) changeBranch:(NSMenuItem *)sender;
// - (void) selectCurrentBranch;
// - (void) updateBranchMenus;
// - (void) updateAllBranchesMenuWithLocal:(NSMutableArray *)localBranches remote:(NSMutableArray *)remoteBranches tag:(NSMutableArray *)tags other:(NSMutableArray *)other;
// - (void) updatePopUpToolbarItemMenu:(KBPopUpToolbarItem *)item remotes:(NSMutableArray *)remoteBranches action:(SEL)action title:(NSString *)menuTitle;
// 
// - (void) pullMenuAction:(NSMenuItem *)sender;
// - (void) pushMenuAction:(NSMenuItem *)sender;
// - (void) rebaseMenuAction:(NSMenuItem *)sender;
// 
// - (BOOL) pullImpl:(NSString *)refName;
// - (BOOL) pushImpl:(NSString *)refName;
// - (BOOL) rebaseImpl:(NSString *)refName;
// - (BOOL) fetchImpl:(NSString *)refName;
// - (BOOL) addRemoteImplWithName:(NSString *)remoteName forURL:(NSString *)remoteURL;
// 
// - (void) showMessageSheet:(NSString *)title message:(NSString *)msg;
// - (void) toggleToolbarItems:(NSToolbar *)tb matchingLabels:(NSArray *)labels enabledState:(BOOL)state;
// - (BOOL) validateToolbarItem:(NSToolbarItem *)theItem;
// =======
- (void) fetchRemote:(PBRefMenuItem *)sender;
- (void) pullRemote:(PBRefMenuItem *)sender;
- (void) pushUpdatesToRemote:(PBRefMenuItem *)sender;
- (void) pushDefaultRemoteForRef:(PBRefMenuItem *)sender;
- (void) pushToRemote:(PBRefMenuItem *)sender;
- (void) showConfirmPushRefSheet:(PBGitRef *)ref remote:(PBGitRef *)remoteRef;

- (void) checkout:(PBRefMenuItem *)sender;
- (void) merge:(PBRefMenuItem *)sender;
- (void) cherryPick:(PBRefMenuItem *)sender;
- (void) rebaseHeadBranch:(PBRefMenuItem *)sender;
- (void) createBranch:(PBRefMenuItem *)sender;
- (void) copySHA:(PBRefMenuItem *)sender;
- (void) copyPatch:(PBRefMenuItem *)sender;
- (void) diffWithHEAD:(PBRefMenuItem *)sender;
- (void) createTag:(PBRefMenuItem *)sender;
- (void) showTagInfoSheet:(PBRefMenuItem *)sender;

- (NSArray *) menuItemsForRef:(PBGitRef *)ref;
- (NSArray *) menuItemsForCommit:(PBGitCommit *)commit;

// >>>>>>> 096a176fbd169d7d93ebf71c3ec605bb6cabd366

@end

@interface NSString (PBRefSpecAdditions)
- (NSString *) refForSpec;
@end