//
//  PBCloneRepsitoryToSheet.h
//  GitX
//
//  Created by Nathan Kinsinger on 2/7/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PBGitRepository;

@interface PBCloneRepsitoryToSheet : NSWindowController {
	PBGitRepository *repository;

	BOOL isBare;

	NSTextField *message;
	NSView      *cloneToAccessoryView;
}

+ (void) beginCloneRepsitoryToSheetForRepository:(PBGitRepository *)repo;


@property (readwrite) PBGitRepository *repository;

@property (readwrite) BOOL isBare;

@property (readwrite) IBOutlet NSTextField *message;
@property (readwrite) IBOutlet NSView      *cloneToAccessoryView;

@end
