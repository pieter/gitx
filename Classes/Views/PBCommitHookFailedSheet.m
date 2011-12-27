//
//  PBCommitHookFailedSheet.m
//  GitX
//
//  Created by Sebastian Staudt on 9/12/10.
//  Copyright 2010 Sebastian Staudt. All rights reserved.
//

#import "PBCommitHookFailedSheet.h"
#import "PBGitWindowController.h"


@implementation PBCommitHookFailedSheet

#pragma mark -
#pragma mark PBCommitHookFailedSheet

+ (void)beginMessageSheetForWindow:(NSWindow *)parentWindow withMessageText:(NSString *)message infoText:(NSString *)info commitController:(PBGitCommitController *)controller 
{
	PBCommitHookFailedSheet *sheet = [[self alloc] initWithWindowNibName:@"PBCommitHookFailedSheet" andController:controller];
	[sheet beginMessageSheetForWindow:parentWindow withMessageText:message infoText:info];
}

- (id)initWithWindowNibName:(NSString *)windowNibName andController:(PBGitCommitController *)controller;
{
    self = [self initWithWindowNibName:windowNibName];
    commitController = controller;

    return self;
}

- (IBAction)forceCommit:(id)sender
{
	[self closeMessageSheet:self];
    [commitController forceCommit:sender];
}

@end
