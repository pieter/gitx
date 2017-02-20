//
//  PBCreateBranchSheet.m
//  GitX
//
//  Created by Nathan Kinsinger on 12/13/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import "PBCreateBranchSheet.h"
#import "PBGitRepository.h"
#import "PBGitDefaults.h"
#import "PBGitCommit.h"
#import "PBGitRef.h"
#import "PBGitWindowController.h"
#import "PBGitRepositoryDocument.h"

@implementation PBCreateBranchSheet

#pragma mark -
#pragma mark PBCreateBranchSheet

+ (void)beginSheetWithRefish:(id <PBGitRefish>)ref windowController:(PBGitWindowController *)windowController
{
	PBCreateBranchSheet *sheet = [[self alloc] initWithWindowController:windowController atRefish:ref];
	[sheet beginCreateBranchSheetAtRefish:ref];
}


- (id)initWithWindowController:(PBGitWindowController *)windowController atRefish:(id<PBGitRefish>)ref
{
	NSParameterAssert(windowController != nil);
	NSParameterAssert(ref != nil);

	self = [super initWithWindowNibName:@"PBCreateBranchSheet" windowController:windowController];
	if (!self)
		return nil;

	self.startRefish = ref;
	
	return self;
}

- (void) beginCreateBranchSheetAtRefish:(id <PBGitRefish>)ref
{
	[self window]; // loads the window (if it wasn't already)
	[self.errorMessageField setStringValue:@""];
	self.shouldCheckoutBranch = [PBGitDefaults shouldCheckoutBranch];

	// when creating a local branch tracking a remote branch preset the branch name to the 	name of the remote branch
	if ([self.startRefish refishType] == kGitXRemoteBranchType) {
		NSMutableArray *components = [[[self.startRefish shortName] componentsSeparatedByString:@"/"] mutableCopy];
		if ([components count] > 1) {
			[components removeObjectAtIndex:0];
			NSString *branchName = [components componentsJoinedByString:@"/"];
			[self.branchNameField setStringValue:branchName];
		}
	}
	
	[self show];
}



#pragma mark IBActions

- (IBAction) createBranch:(id)sender
{
	NSString *name = [self.branchNameField stringValue];
	PBGitRef *ref = [PBGitRef refFromString:[kGitXBranchRefPrefix stringByAppendingString:name]];

	if (![self.repository checkRefFormat:[ref ref]]) {
		[self.errorMessageField setStringValue:NSLocalizedString(@"Invalid name", @"Error message for create branch command when the entered name cannot be used as a branch name")];
		[self.errorMessageField setHidden:NO];
		return;
	}

	if ([self.repository refExists:ref]) {
		[self.errorMessageField setStringValue:NSLocalizedString(@"Branch already exists", @"Error message for create branch command")];
		[self.errorMessageField setHidden:NO];
		return;
	}

	PBCreateBranchSheet *ownRef = self; // ensures self exists after close
	[ownRef closeCreateBranchSheet:ownRef];

	NSError *error = nil;
	BOOL success = [self.repository createBranch:name atRefish:ownRef.startRefish error:&error];
	if (!success) {
		[self.windowController showErrorSheet:error];
		return;
	}

	[PBGitDefaults setShouldCheckoutBranch:ownRef.shouldCheckoutBranch];

	if (ownRef.shouldCheckoutBranch) {
		success = [self.repository checkoutRefish:ref error:&error];
		if (!success) {
			[self.windowController showErrorSheet:error];
			return;
		}
	}
}


- (IBAction) closeCreateBranchSheet:(id)sender
{
	[self hide];
}

@end
