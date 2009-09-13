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


@interface PBGitCommitController (PrivateMethods)
- (void)processHunk:(NSString *)hunk stage:(BOOL)stage reverse:(BOOL)reverse;
@end

@implementation PBGitCommitController

@synthesize status, index;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller
{
	if (!(self = [super initWithRepository:theRepository superController:controller]))
		return nil;

	index = [[PBGitIndex alloc] initWithRepository:theRepository workingDirectory:[NSURL fileURLWithPath:[theRepository workingDirectory]]];
	[index refresh];
	return self;
}

- (BOOL)busy
{
	return NO;
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
	[index refresh];

	// Reload refs (in case HEAD changed)
	[repository reloadRefs];
}

- (void) updateView
{
	[self refresh:nil];
}

- (void) commitFailedBecause:(NSString *)reason
{
	//self.busy--;
	self.status = [@"Commit failed: " stringByAppendingString:reason];
	[[repository windowController] showMessageSheet:@"Commit failed" infoText:reason];
	return;
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

	[index commitWithMessage:commitMessage];

	[webController setStateMessage:[NSString stringWithFormat:@"Successfully created commit"]];

	[commitMessageView setString:@""];
}

- (void) stageHunk:(NSString *)hunk reverse:(BOOL)reverse
{
	[self processHunk:hunk stage:TRUE reverse:reverse];
}

- (void)discardHunk:(NSString *)hunk
{
	[self processHunk:hunk stage:FALSE reverse:TRUE];
}

- (void)processHunk:(NSString *)hunk stage:(BOOL)stage reverse:(BOOL)reverse
{
	NSMutableArray *array = [NSMutableArray arrayWithObjects:@"apply", nil];
	if (stage)
		[array addObject:@"--cached"];
	if (reverse)
		[array addObject:@"--reverse"];

	int ret = 1;
	NSString *error = [repository outputForArguments:array
										 inputString:hunk
											retValue:&ret];

	// FIXME: show this error, rather than just logging it
	if (ret)
		NSLog(@"Error: %@", error);

	// TODO: We should do this smarter by checking if the file diff is empty, which is faster.
	[self refresh:self]; 
}

@end
