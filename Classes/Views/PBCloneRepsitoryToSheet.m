//
//  PBCloneRepsitoryToSheet.m
//  GitX
//
//  Created by Nathan Kinsinger on 2/7/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import "PBCloneRepsitoryToSheet.h"
#import "PBGitRepository.h"
#import "PBGitWindowController.h"


@interface PBCloneRepsitoryToSheet ()

- (void) beginCloneRepsitoryToSheetForRepository:(PBGitRepository *)repo;

@end


@implementation PBCloneRepsitoryToSheet

@synthesize repository;
@synthesize isBare;
@synthesize message;
@synthesize cloneToAccessoryView;


#pragma mark -
#pragma mark PBCloneRepsitoryToSheet

+ (void) beginCloneRepsitoryToSheetForRepository:(PBGitRepository *)repo
{
	PBCloneRepsitoryToSheet *sheet = [[self alloc] initWithWindowNibName:@"PBCloneRepsitoryToSheet"];
	[sheet beginCloneRepsitoryToSheetForRepository:repo];
}


- (void) beginCloneRepsitoryToSheetForRepository:(PBGitRepository *)repo
{
	self.repository = repo;
	[self window];
}


- (void) awakeFromNib
{
    NSOpenPanel *cloneToSheet = [NSOpenPanel openPanel];

	[cloneToSheet setTitle:@"Clone Repository To"];
	[cloneToSheet setPrompt:@"Clone"];
    [self.message setStringValue:[NSString stringWithFormat:@"Select a folder to clone %@ into", [self.repository projectName]]];
    [cloneToSheet setCanSelectHiddenExtension:NO];
    [cloneToSheet setCanChooseFiles:NO];
    [cloneToSheet setCanChooseDirectories:YES];
    [cloneToSheet setAllowsMultipleSelection:NO];
    [cloneToSheet setCanCreateDirectories:YES];
	[cloneToSheet setAccessoryView:cloneToAccessoryView];

    [cloneToSheet beginSheetForDirectory:nil file:nil types:nil
						  modalForWindow:[self.repository.windowController window]
						   modalDelegate:self
						  didEndSelector:@selector(cloneToSheetDidEnd:returnCode:contextInfo:)
							 contextInfo:NULL];
}
	

- (void) cloneToSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)code contextInfo:(void *)info
{
    [sheet orderOut:self];

    if (code == NSOKButton) {
		NSString *clonePath = [(NSOpenPanel *)sheet filename];
		NSLog(@"clone path = %@", clonePath);
		[self.repository cloneRepositoryToPath:clonePath bare:self.isBare];
	}
}


@end
