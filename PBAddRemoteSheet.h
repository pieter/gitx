//
//  PBAddRemoteSheet.h
//  GitX
//
//  Created by Nathan Kinsinger on 12/8/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PBGitRepository;

@interface PBAddRemoteSheet : NSWindowController {
	PBGitRepository *repository;

	NSTextField *remoteName;
	NSTextField *remoteURL;
	NSTextField *errorMessage;

	NSOpenPanel *browseSheet;
	NSView      *browseAccessoryView;
}

+ (void) beginAddRemoteSheetForRepository:(PBGitRepository *)repo;

- (IBAction) browseFolders:(id)sender;
- (IBAction) addRemote:(id)sender;
- (IBAction) orderOutAddRemoteSheet:(id)sender;
- (IBAction) showHideHiddenFiles:(id)sender;


@property (readwrite) PBGitRepository *repository;

@property (readwrite) IBOutlet NSTextField *remoteName;
@property (readwrite) IBOutlet NSTextField *remoteURL;
@property (readwrite) IBOutlet NSTextField *errorMessage;

@property (readwrite)          NSOpenPanel *browseSheet;
@property (readwrite) IBOutlet NSView      *browseAccessoryView;

@end
