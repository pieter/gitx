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

@interface PBRefController : NSObject {
	IBOutlet __weak PBGitHistoryController *historyController;
	IBOutlet NSArrayController *commitController;
	IBOutlet PBCommitList *commitList;

	IBOutlet NSWindow *newBranchSheet;
	IBOutlet NSTextField *newBranchName;
}

- (IBAction) addRef:(id)sender;
- (IBAction)closeSheet:(id) sender;
- (IBAction)saveSheet:(id) sender;

@end
