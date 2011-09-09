//
//  PBCreateTagSheet.m
//  GitX
//
//  Created by Nathan Kinsinger on 12/18/09.
//  Copyright 2009 Nathan Kinsinger. All rights reserved.
//

#import "PBCreateTagSheet.h"
#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBGitWindowController.h"

@interface PBCreateTagSheet ()

- (void) beginCreateTagSheetAtRefish:(id <PBGitRefish>)refish inRepository:(PBGitRepository *)repo;

@end


@implementation PBCreateTagSheet

@synthesize repository;
@synthesize targetRefish;

@synthesize tagNameField;
@synthesize tagMessageText;
@synthesize errorMessageField;



#pragma mark -
#pragma mark PBCreateTagSheet

+ (void) beginCreateTagSheetAtRefish:(id <PBGitRefish>)refish inRepository:(PBGitRepository *)repo
{
	PBCreateTagSheet *sheet = [[self alloc] initWithWindowNibName:@"PBCreateTagSheet"];
	[sheet beginCreateTagSheetAtRefish:refish inRepository:repo];
}


- (void) beginCreateTagSheetAtRefish:(id <PBGitRefish>)refish inRepository:(PBGitRepository *)repo
{
	self.repository = repo;
	self.targetRefish  = refish;

	[self window]; // loads the window (if it wasn't already)
	[self.errorMessageField setStringValue:@""];

	[NSApp beginSheet:[self window] modalForWindow:[self.repository.windowController window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}



#pragma mark IBActions

- (IBAction) createTag:(id)sender
{
	NSString *tagName = [self.tagNameField stringValue];
	[self.errorMessageField setHidden:YES];

	NSString *refName = [@"refs/tags/" stringByAppendingString:tagName];
	if (![self.repository checkRefFormat:refName]) {
		[self.errorMessageField setStringValue:@"Invalid name"];
		[self.errorMessageField setHidden:NO];
		return;
	}

	for (PBGitRevSpecifier *rev in self.repository.branches) {
		NSString *name = [[rev ref] tagName];
		if ([tagName isEqualToString:name]) {
			[self.errorMessageField setStringValue:@"Tag already exists"];
			[self.errorMessageField setHidden:NO];
			return;
		}
	}

	[self closeCreateTagSheet:sender];

	NSString *message = [self.tagMessageText string];
	[self.repository createTag:tagName message:message atRefish:self.targetRefish];
}


- (IBAction) closeCreateTagSheet:(id)sender
{
	[NSApp endSheet:[self window]];
	[[self window] orderOut:self];
}



@end
