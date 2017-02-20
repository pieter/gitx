//
//  PBAddRemoteSheet.m
//  GitX
//
//  Created by Nathan Kinsinger on 12/8/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import "PBAddRemoteSheet.h"
#import "PBGitWindowController.h"
#import "PBGitRepository.h"

@implementation PBAddRemoteSheet

#pragma mark -
#pragma mark PBAddRemoteSheet

- (id) initWithRepository:(PBGitRepository *)repo
{
	self = [super initWithWindowNibName:@"PBAddRemoteSheet" forRepo:repo];
	if (!self)
		return nil;

	return self;
}

- (void) show
{
	[self.errorMessage setStringValue:@""];
	[super show];
}

#pragma mark IBActions

- (IBAction) browseFolders:(id)sender
{
	PBAddRemoteSheet *me = self;
	NSOpenPanel *browseSheet = [NSOpenPanel openPanel];

	[browseSheet setTitle:NSLocalizedString(@"Add remote", @"Title of sheet to enter data for a new remote")];
    [browseSheet setMessage:NSLocalizedString(@"Select a folder with a git repository", @"Title of sheet to enter data for a new remote")];
    [browseSheet setCanChooseFiles:NO];
    [browseSheet setCanChooseDirectories:YES];
    [browseSheet setAllowsMultipleSelection:NO];
    [browseSheet setCanCreateDirectories:NO];
	[browseSheet setAccessoryView:me.browseAccessoryView];

	self.browseSheet = browseSheet;
	[me hide];
    [browseSheet beginSheetModalForWindow:me.windowController.window
                        completionHandler:^(NSInteger result) {
                            if (result == NSOKButton) {
                                NSString* directory = browseSheet.directoryURL.path;
                                [me.remoteURL setStringValue:directory];
                            }
                            [me show];
                        }];
}


- (IBAction) addRemote:(id)sender
{
	[self.errorMessage setStringValue:@""];

	NSString *name = [[self.remoteName stringValue] copy];

	if ([name isEqualToString:@""]) {
		[self.errorMessage setStringValue:NSLocalizedString(@"Remote name is required", @"Add Remote error message: missing name")];
		return;
	}

	if (![self.repository checkRefFormat:[@"refs/remotes/" stringByAppendingString:name]]) {
		[self.errorMessage setStringValue:NSLocalizedString(@"Invalid remote name", @"Add Remote error message: invalid name")];
		return;
	}

	NSString *url = [[self.remoteURL stringValue] copy];
	if ([url isEqualToString:@""]) {
		[self.errorMessage setStringValue:NSLocalizedString(@"Remote URL is required", @"Add Remote error message: missing URL")];
		return;
	}

	PBGitRepository* repo = self.repository;
	[self hide]; // may deallocate self
	[repo beginAddRemote:name forURL:url];
}

- (IBAction) showHideHiddenFiles:(id)sender
{
    [self.browseSheet setShowsHiddenFiles:[sender state] == NSOnState];
}

- (IBAction) cancelOperation:(id)sender
{
//	[super cancelOperation:sender];
	[self hide];
}

@end
