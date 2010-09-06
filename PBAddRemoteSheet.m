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



@interface PBAddRemoteSheet ()

- (void) beginAddRemoteSheetForRepository:(PBGitRepository *)repo;
- (void) openAddRemoteSheet;

@end


@implementation PBAddRemoteSheet


@synthesize repository;

@synthesize remoteName;
@synthesize remoteURL;
@synthesize errorMessage;

@synthesize browseSheet;
@synthesize browseAccessoryView;



#pragma mark -
#pragma mark PBAddRemoteSheet

+ (void) beginAddRemoteSheetForRepository:(PBGitRepository *)repo
{
	PBAddRemoteSheet *sheet = [[self alloc] initWithWindowNibName:@"PBAddRemoteSheet"];
	[sheet beginAddRemoteSheetForRepository:repo];
}


- (void) beginAddRemoteSheetForRepository:(PBGitRepository *)repo
{
	self.repository = repo;

	[self window];
	[self openAddRemoteSheet];
}


- (void) openAddRemoteSheet
{
	[self.errorMessage setStringValue:@""];

	[NSApp beginSheet:[self window] modalForWindow:[self.repository.windowController window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}


- (void) browseSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)code contextInfo:(void *)info
{
    [sheet orderOut:self];

    if (code == NSOKButton)
		[self.remoteURL setStringValue:[(NSOpenPanel *)sheet filename]];

	[self openAddRemoteSheet];
}



#pragma mark IBActions

- (IBAction) browseFolders:(id)sender
{
	[self orderOutAddRemoteSheet:nil];

    self.browseSheet = [NSOpenPanel openPanel];

	[browseSheet setTitle:@"Add remote"];
    [browseSheet setMessage:@"Select a folder with a git repository"];
    [browseSheet setCanChooseFiles:NO];
    [browseSheet setCanChooseDirectories:YES];
    [browseSheet setAllowsMultipleSelection:NO];
    [browseSheet setCanCreateDirectories:NO];
	[browseSheet setAccessoryView:browseAccessoryView];

    [browseSheet beginSheetForDirectory:nil file:nil types:nil
						 modalForWindow:[self.repository.windowController window]
						  modalDelegate:self
						 didEndSelector:@selector(browseSheetDidEnd:returnCode:contextInfo:)
							contextInfo:NULL];
}


- (IBAction) addRemote:(id)sender
{
	[self.errorMessage setStringValue:@""];

	NSString *name = [[self.remoteName stringValue] copy];

	if ([name isEqualToString:@""]) {
		[self.errorMessage setStringValue:@"Remote name is required"];
		return;
	}

	if (![self.repository checkRefFormat:[@"refs/remotes/" stringByAppendingString:name]]) {
		[self.errorMessage setStringValue:@"Invalid remote name"];
		return;
	}

	NSString *url = [[self.remoteURL stringValue] copy];
	if ([url isEqualToString:@""]) {
		[self.errorMessage setStringValue:@"Remote URL is required"];
		return;
	}

	[self orderOutAddRemoteSheet:self];
	[self.repository beginAddRemote:name forURL:url];
}


- (IBAction) orderOutAddRemoteSheet:(id)sender
{
	[NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}


- (IBAction) showHideHiddenFiles:(id)sender
{
	// This uses undocumented OpenPanel features to show hidden files (required for 10.5 support)
	NSNumber *showHidden = [NSNumber numberWithBool:[sender state] == NSOnState];
	[[self.browseSheet valueForKey:@"_navView"] setValue:showHidden forKey:@"showsHiddenFiles"];
}


@end
