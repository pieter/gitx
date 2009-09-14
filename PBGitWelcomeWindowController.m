//
//  PBGitWelcomeWindowController.m
//  GitX
//
//  Created by Pieter de Bie on 9/14/09.
//  Copyright 2009 Pieter de Bie. All rights reserved.
//

#import "PBGitWelcomeWindowController.h"
#import "PBRepositoryDocumentController.h"
#import "PBRepositoryCell.h"

@interface PBGitWelcomeWindowController ()

- (void)populateRecentItems;

@end

@implementation PBGitWelcomeWindowController

@synthesize recentItems;

- (id)init
{
	if (!(self = [super initWithWindowNibName:@"PBGitWelcomeWindow"]))
		return nil;

	[self populateRecentItems];
	return self;
}

- (void)awakeFromNib
{
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(open:)];
}

- (void)populateRecentItems;
{
	NSArray *recentURLs = [[PBRepositoryDocumentController sharedDocumentController] recentDocumentURLs];
	recentItems = [recentURLs valueForKey:@"path"];
}

- (IBAction)cancel:(id)sender
{
	[[self window] close];
}

- (IBAction)openOther:(id)sender
{
	[[PBRepositoryDocumentController sharedDocumentController] openDocument:self];
}

- (IBAction)open:(id)sender
{
	if ([[itemController selectedObjects] count] == 0)
		return;

	NSString *path = [[itemController selectedObjects] objectAtIndex:0];
	NSURL *url = [NSURL fileURLWithPath:path];
	NSError *error = nil;
	[[PBRepositoryDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url
																					 display:YES
																					   error:&error];
	if (error)
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	else
		[self close];
}
@end
