//
//  PBCommitHookFailedSheet.h
//  GitX
//
//  Created by Sebastian Staudt on 9/12/10.
//  Copyright 2010 Sebastian Staudt. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PBGitCommitController.h"
#import "PBGitXMessageSheet.h"


@interface PBCommitHookFailedSheet : PBGitXMessageSheet
{
    PBGitCommitController *commitController;
}

+ (void)beginMessageSheetForWindow:(NSWindow *)parentWindow withMessageText:(NSString *)message infoText:(NSString *)info commitController:(PBGitCommitController *)controller;

- (id)initWithWindowNibName:(NSString *)windowNibName andController:(PBGitCommitController *)controller;
- (IBAction)forceCommit:(id)sender;

@end