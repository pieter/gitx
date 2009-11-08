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

@interface PBRefController : NSObject <PBRefContextDelegate> {
	IBOutlet __weak PBGitHistoryController *historyController;
	IBOutlet NSArrayController *commitController;
	IBOutlet PBCommitList *commitList;

	IBOutlet NSWindow *newBranchSheet;
	IBOutlet NSTextField *newBranchName;
	IBOutlet NSTextField *errorMessage;
    
	IBOutlet NSWindow *addRemoteSheet;
	IBOutlet NSTextField *addRemoteName;
	IBOutlet NSTextField *addRemoteURL;
	IBOutlet NSTextField *addRemoteErrorMessage;    

	IBOutlet NSWindow *newTagSheet;
	IBOutlet NSTextField *newTagName;
    IBOutlet NSTextView *newTagMessage;
	IBOutlet NSTextField *newTagErrorMessage;
	IBOutlet NSTextField *newTagCommit;
	IBOutlet NSTextField *newTagSHA;
	IBOutlet NSTextField *newTagSHALabel;

	IBOutlet NSPopUpButton *branchPopUp;
}

- (IBAction)addRef:(id)sender;
- (IBAction)closeSheet:(id) sender;
- (IBAction)saveSheet:(id) sender;

- (IBAction)rebaseButton:(id)sender;
- (IBAction)pushButton:(id)sender;
- (IBAction)pullButton:(id)sender;
- (IBAction)fetchButton:(id)sender;

- (IBAction)addRemoteButton:(id)sender;
- (IBAction)addRemoteSheet:(id)sender;
- (IBAction)closeAddRemoteSheet:(id)sender;

- (IBAction)newTagButton:(id)sender;
- (IBAction)newTagSheet:(id)sender;
- (IBAction)closeNewTagSheet:(id)sender;

- (NSArray *) menuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit;

- (void) changeBranch:(NSMenuItem *)sender;
- (void) selectCurrentBranch;
- (void) updateBranchMenu;

- (BOOL) pullImpl:(NSString *)refName;
- (BOOL) pushImpl:(NSString *)refName;
- (BOOL) rebaseImpl:(NSString *)refName;
- (BOOL) fetchImpl:(NSString *)refName;
- (BOOL) addRemoteImplWithName:(NSString *)remoteName forURL:(NSString *)remoteURL;

- (void) showMessageSheet:(NSString *)title message:(NSString *)msg;

@end

@interface NSString (PBRefSpecAdditions)
- (NSString *) refForSpec;
@end