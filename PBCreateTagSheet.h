//
//  PBCreateTagSheet.h
//  GitX
//
//  Created by Nathan Kinsinger on 12/18/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRefish.h"


@class PBGitRepository;


@interface PBCreateTagSheet : NSWindowController {
	PBGitRepository *repository;
	id <PBGitRefish> targetRefish;

	NSTextField *tagNameField;
	NSTextView  *tagMessageText;
	NSTextField *errorMessageField;
}

+ (void) beginCreateTagSheetAtRefish:(id <PBGitRefish>)refish inRepository:(PBGitRepository *)repo;

- (IBAction) createTag:(id)sender;
- (IBAction) closeCreateTagSheet:(id)sender;


@property (retain) PBGitRepository *repository;
@property (retain) id <PBGitRefish> targetRefish;

@property (assign) IBOutlet NSTextField *tagNameField;
@property (assign) IBOutlet NSTextView  *tagMessageText;
@property (assign) IBOutlet NSTextField *errorMessageField;

@end
