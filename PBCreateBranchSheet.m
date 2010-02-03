//
//  PBCreateBranchSheet.m
//  GitX
//
//  Created by Nathan Kinsinger on 12/13/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import "PBCreateBranchSheet.h"
#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBGitRef.h"

@interface PBCreateBranchSheet ()

- (void) beginCreateBranchSheetAtRefish:(id <PBGitRefish>)ref inRepository:(PBGitRepository *)repo;

@end


@implementation PBCreateBranchSheet


@synthesize repository;
@synthesize startRefish;

@synthesize branchNameField;
@synthesize errorMessageField;



#pragma mark -
#pragma mark PBCreateBranchSheet

+ (void) beginCreateBranchSheetAtRefish:(id <PBGitRefish>)ref inRepository:(PBGitRepository *)repo
{
	PBCreateBranchSheet *sheet = [[self alloc] initWithWindowNibName:@"PBCreateBranchSheet"];
	[sheet beginCreateBranchSheetAtRefish:ref inRepository:repo];
}


- (void) beginCreateBranchSheetAtRefish:(id <PBGitRefish>)ref inRepository:(PBGitRepository *)repo
{
	self.repository = repo;
	self.startRefish   = ref;

	[self window]; // loads the window (if it wasn't already)
	[self.errorMessageField setStringValue:@""];

	[NSApp beginSheet:[self window] modalForWindow:[self.repository.windowController window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}



#pragma mark IBActions

- (IBAction) createBranch:(id)sender
{
	NSString *name = [self.branchNameField stringValue];
	PBGitRef *ref = [PBGitRef refFromString:[@"refs/heads/" stringByAppendingString:name]];

	if (![self.repository checkRefFormat:[ref ref]]) {
		[self.errorMessageField setStringValue:@"Invalid name"];
		[self.errorMessageField setHidden:NO];
		return;
	}
	
	if ([self.repository refExists:ref]) {
		[self.errorMessageField setStringValue:@"Branch already exists"];
		[self.errorMessageField setHidden:NO];
		return;
	}

	[self closeCreateBranchSheet:self];

	[self.repository createBranch:name atRefish:self.startRefish];
}


- (IBAction) closeCreateBranchSheet:(id)sender
{
	[NSApp endSheet:[self window]];
	[[self window] orderOut:self];
}



@end
