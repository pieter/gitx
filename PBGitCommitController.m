//
//  PBGitCommitController.m
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitCommitController.h"
#import "NSFileHandleExt.h"
#import "PBChangedFile.h"
#import "PBWebChangesController.h"
#import "PBGitIndex.h"
#import "NSString_RegEx.h"


@interface PBGitCommitController ()
- (void)refreshFinished:(NSNotification *)notification;
- (void)commitStatusUpdated:(NSNotification *)notification;
- (void)commitFinished:(NSNotification *)notification;
- (void)commitFailed:(NSNotification *)notification;
@end

@implementation PBGitCommitController

@synthesize status, index, busy;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller
{
	if (!(self = [super initWithRepository:theRepository superController:controller]))
		return nil;

	index = [[PBGitIndex alloc] initWithRepository:theRepository workingDirectory:[NSURL fileURLWithPath:[theRepository workingDirectory]]];
	[index refresh];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFinished:) name:PBGitIndexFinishedIndexRefresh object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitStatusUpdated:) name:PBGitIndexCommitStatus object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitFinished:) name:PBGitIndexFinishedCommit object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitFailed:) name:PBGitIndexCommitFailed object:index];

	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];

	[commitMessageView setTypingAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Monaco" size:12.0] forKey:NSFontAttributeName]];
	
	[unstagedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"hasUnstagedChanges == 1"]];
	[cachedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"hasStagedChanges == 1"]];
	
	[unstagedFilesController setSortDescriptors:[NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"status" ascending:false],
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true], nil]];
	[cachedFilesController setSortDescriptors:[NSArray arrayWithObject:
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true]]];
}
- (void) removeView
{
	[webController closeView];
	[super finalize];
}
- (NSResponder *)firstResponder;
{
	return commitMessageView;
}

- (IBAction)signOff:(id)sender
{
	if (![repository.config valueForKeyPath:@"user.name"] || ![repository.config valueForKeyPath:@"user.email"])
		return [[repository windowController] showMessageSheet:@"User's name not set" infoText:@"Signing off a commit requires setting user.name and user.email in your git config"];
	NSString *SOBline = [NSString stringWithFormat:@"Signed-off-by: %@ <%@>",
				[repository.config valueForKeyPath:@"user.name"],
				[repository.config valueForKeyPath:@"user.email"]];

	if([commitMessageView.string rangeOfString:SOBline].location == NSNotFound) {
		NSArray *selectedRanges = [commitMessageView selectedRanges];
		commitMessageView.string = [NSString stringWithFormat:@"%@\n\n%@",
				commitMessageView.string, SOBline];
		[commitMessageView setSelectedRanges: selectedRanges];
	}
}

- (void) refresh:(id) sender
{
	self.busy = YES;
	self.status = @"Refreshing index…";
	[index refresh];

	// Reload refs (in case HEAD changed)
	[repository reloadRefs];
}

- (void) updateView
{
	[self refresh:nil];
}

- (IBAction) commit:(id) sender
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:[repository.fileURL.path stringByAppendingPathComponent:@"MERGE_HEAD"]]) {
		[[repository windowController] showMessageSheet:@"Cannot commit merges" infoText:@"GitX cannot commit merges yet. Please commit your changes from the command line."];
		return;
	}

	if ([[cachedFilesController arrangedObjects] count] == 0) {
		[[repository windowController] showMessageSheet:@"No changes to commit" infoText:@"You must first stage some changes before committing"];
		return;
	}		
	
	NSString *commitMessage = [commitMessageView string];
	if ([commitMessage length] < 3) {
		[[repository windowController] showMessageSheet:@"Commitmessage missing" infoText:@"Please enter a commit message before committing"];
		return;
	}

	[cachedFilesController setSelectionIndexes:[NSIndexSet indexSet]];
	[unstagedFilesController setSelectionIndexes:[NSIndexSet indexSet]];

	self.busy = YES;

	[index commitWithMessage:commitMessage];
	[commitMessageView setEditable:NO];
}


- (void)refreshFinished:(NSNotification *)notification
{
	self.busy = NO;
	self.status = @"Index refresh finished";
}

- (void)commitStatusUpdated:(NSNotification *)notification
{
	self.status = [[notification userInfo] objectForKey:@"description"];
}

- (void)commitFinished:(NSNotification *)notification
{
	[commitMessageView setString:@""];
	[webController setStateMessage:[NSString stringWithFormat:[[notification userInfo] objectForKey:@"description"]]];
	[commitMessageView setEditable:YES];
}	

- (void)commitFailed:(NSNotification *)notification
{
	self.busy = NO;
	NSString *reason = [[notification userInfo] objectForKey:@"description"];
	self.status = [@"Commit failed: " stringByAppendingString:reason];
	[[repository windowController] showMessageSheet:@"Commit failed" infoText:reason];
}


@end
