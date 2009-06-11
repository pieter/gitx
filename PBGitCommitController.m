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
#import "NSString_RegEx.h"


@interface PBGitCommitController (PrivateMethods)
- (NSArray *) linesFromNotification:(NSNotification *)notification;
- (void) doneProcessingIndex;
- (NSMutableDictionary *)dictionaryForLines:(NSArray *)lines;
- (void) addFilesFromDictionary:(NSMutableDictionary *)dictionary staged:(BOOL)staged tracked:(BOOL)tracked;
- (void)processHunk:(NSString *)hunk stage:(BOOL)stage reverse:(BOOL)reverse;
@end

@implementation PBGitCommitController

@synthesize files, status, busy, amend;

- (void)awakeFromNib
{
	self.files = [NSMutableArray array];
	[super awakeFromNib];
	[self refresh:self];

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

- (IBAction)signOff:(id)sender
{
	if (![repository.config valueForKeyPath:@"user.name"] || ![repository.config valueForKeyPath:@"user.email"])
		return [[repository windowController] showMessageSheet:@"User's name not set" infoText:@"Signing off a commit requires setting user.name and user.email in your git config"];

	commitMessageView.string = [NSString stringWithFormat:@"%@\n\nSigned-off-by: %@ <%@>",
		commitMessageView.string,
		[repository.config valueForKeyPath:@"user.name"],
		[repository.config valueForKeyPath:@"user.email"]];
}

- (void) setAmend:(BOOL)newAmend
{
	if (newAmend == amend)
		return;

	amend = newAmend;
	amendEnvironment = nil;

	// If we amend, we want to keep the author information for the previous commit
	// We do this by reading in the previous commit, and storing the information
	// in a dictionary. This dictionary will then later be read by [self commit:]
	if (amend) {
		NSString *message = [repository outputForCommand:@"cat-file commit HEAD"];
		NSArray *match = [message substringsMatchingRegularExpression:@"\nauthor ([^\n]*) <([^\n>]*)> ([0-9]+[^\n]*)\n" count:3 options:0 ranges:nil error:nil];
		if (match)
			amendEnvironment = [NSDictionary dictionaryWithObjectsAndKeys:[match objectAtIndex:1], @"GIT_AUTHOR_NAME",
				[match objectAtIndex:2], @"GIT_AUTHOR_EMAIL",
				[match objectAtIndex:3], @"GIT_AUTHOR_DATE",
				 nil];

		// Replace commit message with the old one if it's less than 3 characters long.
		// This is just a random number.
		if ([[commitMessageView string] length] <= 3) {
			// Find the commit message
			NSRange r = [message rangeOfString:@"\n\n"];
			if (r.location != NSNotFound)
				message = [message substringFromIndex:r.location + 2];

			commitMessageView.string = message;
		}
	}

	[self refresh:self];
}

- (NSArray *) linesFromNotification:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	NSData *data = [userInfo valueForKey:NSFileHandleNotificationDataItem];
	if (!data)
		return NULL;
	
	NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!string)
		return NULL;
	
	// Strip trailing newline
	if ([string hasSuffix:@"\n"])
		string = [string substringToIndex:[string length]-1];
	
	NSArray *lines = [string componentsSeparatedByString:@"\0"];
	return lines;
}

- (NSString *) parentTree
{
	NSString *parent = amend ? @"HEAD^" : @"HEAD";

	if (![repository parseReference:parent])
		// We don't have a head ref. Return the empty tree.
		return @"4b825dc642cb6eb9a060e54bf8d69288fbee4904";

	return parent;
}

- (void) refresh:(id) sender
{
	if (![repository workingDirectory])
		return;

	self.status = @"Refreshing index…";

	// If self.busy reaches 0, all tasks have finished
	self.busy = 0;

	// Refresh the index, necessary for the next methods (that's why it's blocking)
	// FIXME: Make this non-blocking. This call can be expensive in large repositories
	[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"update-index", @"-q", @"--unmerged", @"--ignore-missing", @"--refresh", nil]];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; 
	[nc removeObserver:self]; 

	// Other files (not tracked, not ignored)
	NSArray *arguments = [NSArray arrayWithObjects:@"ls-files", @"--others", @"--exclude-standard", @"-z", nil];
	NSFileHandle *handle = [repository handleInWorkDirForArguments:arguments];
	[nc addObserver:self selector:@selector(readOtherFiles:) name:NSFileHandleReadToEndOfFileCompletionNotification object:handle]; 
	self.busy++;
	[handle readToEndOfFileInBackgroundAndNotify];
	
	// Unstaged files
	handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObjects:@"diff-files", @"-z", nil]];
	[nc addObserver:self selector:@selector(readUnstagedFiles:) name:NSFileHandleReadToEndOfFileCompletionNotification object:handle]; 
	self.busy++;
	[handle readToEndOfFileInBackgroundAndNotify];

	// Staged files
	handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObjects:@"diff-index", @"--cached", @"-z", [self parentTree], nil]];
	[nc addObserver:self selector:@selector(readCachedFiles:) name:NSFileHandleReadToEndOfFileCompletionNotification object:handle]; 
	self.busy++;
	[handle readToEndOfFileInBackgroundAndNotify];
}

- (void) updateView
{
	[self refresh:nil];
}

// This method is called for each of the three processes from above.
// If all three are finished (self.busy == 0), then we can delete
// all files previously marked as deletable
- (void) doneProcessingIndex
{
	// if we're still busy, do nothing :)
	if (--self.busy)
		return;

	NSMutableArray *deleteFiles = [NSMutableArray array];
	for (PBChangedFile *file in files) {
		if (!file.hasStagedChanges && !file.hasUnstagedChanges)
			[deleteFiles addObject:file];
	}

	if ([deleteFiles count]) {
		[self willChangeValueForKey:@"files"];
		for (PBChangedFile *file in deleteFiles)
			[files removeObject:file];
		[self didChangeValueForKey:@"files"];
	}
	self.status = @"Ready";
}

- (void) readOtherFiles:(NSNotification *)notification;
{
	[unstagedFilesController setAutomaticallyRearrangesObjects:NO];
	NSArray *lines = [self linesFromNotification:notification];
	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[lines count]];
	// We fake this files status as good as possible.
	NSArray *fileStatus = [NSArray arrayWithObjects:@":000000", @"100644", @"0000000000000000000000000000000000000000", @"0000000000000000000000000000000000000000", @"A", nil];
	for (NSString *path in lines) {
		if ([path length] == 0)
			continue;
		[dictionary setObject:fileStatus forKey:path];
	}
	[self addFilesFromDictionary:dictionary staged:NO tracked:NO];
	[self doneProcessingIndex];
}

- (NSMutableDictionary *)dictionaryForLines:(NSArray *)lines
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[lines count]/2];

	// Fill the dictionary with the new information
	NSArray *fileStatus;
	BOOL even = FALSE;
	for (NSString *line in lines) {
		if (!even) {
			even = TRUE;
			fileStatus = [line componentsSeparatedByString:@" "];
			continue;
		}

		even = FALSE;
		[dictionary setObject:fileStatus forKey:line];
	}
	return dictionary;
}

- (void) addFilesFromDictionary:(NSMutableDictionary *)dictionary staged:(BOOL)staged tracked:(BOOL)tracked
{
	// Iterate over all existing files
	for (PBChangedFile *file in files) {
		NSArray *fileStatus = [dictionary objectForKey:file.path];
		// Object found, this is still a cached / uncached thing
		if (fileStatus) {
			if (tracked) {
				NSString *mode = [[fileStatus objectAtIndex:0] substringFromIndex:1];
				NSString *sha = [fileStatus objectAtIndex:2];

				if (staged) {
					file.hasStagedChanges = YES;
					file.commitBlobSHA = sha;
					file.commitBlobMode = mode;
				} else
					file.hasUnstagedChanges = YES;
			} else {
				// Untracked file, set status to NEW, only unstaged changes
				file.hasStagedChanges = NO;
				file.hasUnstagedChanges = YES;
				file.status = NEW;
			}
			[dictionary removeObjectForKey:file.path];
		} else { // Object not found, let's remove it from the changes
			if (staged)
				file.hasStagedChanges = NO;
			else if (tracked && file.status != NEW) // Only remove it if it's not an untracked file. We handle that with the other thing
				file.hasUnstagedChanges = NO;
			else if (!tracked && file.status == NEW)
				file.hasUnstagedChanges = NO;
		}
	}

	// Do new files
	for (NSString *path in [dictionary allKeys]) {
		NSArray *fileStatus = [dictionary objectForKey:path];

		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:path];
		if ([[fileStatus objectAtIndex:4] isEqualToString:@"D"])
			file.status = DELETED;
		else if([[fileStatus objectAtIndex:0] isEqualToString:@":000000"])
			file.status = NEW;
		else
			file.status = MODIFIED;

		if (staged) {
			file.commitBlobMode = [[fileStatus objectAtIndex:0] substringFromIndex:1];
			file.commitBlobSHA = [fileStatus objectAtIndex:2];
		}

		file.hasStagedChanges = staged;
		file.hasUnstagedChanges = !staged;

		[files addObject: file];
	}
}

- (void) readUnstagedFiles:(NSNotification *)notification
{
	NSArray *lines = [self linesFromNotification:notification];
	NSMutableDictionary *dic = [self dictionaryForLines:lines];
	[self addFilesFromDictionary:dic staged:NO tracked:YES];
	[self doneProcessingIndex];
}

- (void) readCachedFiles:(NSNotification *)notification
{
	NSArray *lines = [self linesFromNotification:notification];
	NSMutableDictionary *dic = [self dictionaryForLines:lines];
	[self addFilesFromDictionary:dic staged:YES tracked:YES];
	[self doneProcessingIndex];
}

- (void) commitFailedBecause:(NSString *)reason
{
	self.busy--;
	self.status = [@"Commit failed: " stringByAppendingString:reason];
	[[repository windowController] showMessageSheet:@"Commit failed" infoText:reason];
	return;
}

- (IBAction) commit:(id) sender
{
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

	NSString *commitSubject;
	NSRange newLine = [commitMessage rangeOfString:@"\n"];
	if (newLine.location == NSNotFound)
		commitSubject = commitMessage;
	else
		commitSubject = [commitMessage substringToIndex:newLine.location];
	
	commitSubject = [@"commit: " stringByAppendingString:commitSubject];

	NSString *commitMessageFile;
	commitMessageFile = [repository.fileURL.path
						 stringByAppendingPathComponent:@"COMMIT_EDITMSG"];

	[commitMessage writeToFile:commitMessageFile atomically:YES encoding:NSUTF8StringEncoding error:nil];

	self.busy++;
	self.status = @"Creating tree..";
	NSString *tree = [repository outputForCommand:@"write-tree"];
	if ([tree length] != 40)
		return [self commitFailedBecause:@"Could not create a tree"];

	int ret;

	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"commit-tree", tree, nil];
	NSString *parent = amend ? @"HEAD^" : @"HEAD";
	if ([repository parseReference:parent]) {
		[arguments addObject:@"-p"];
		[arguments addObject:parent];
	}

	NSString *commit = [repository outputForArguments:arguments
										  inputString:commitMessage
							   byExtendingEnvironment:amendEnvironment
											 retValue: &ret];

	if (ret || [commit length] != 40)
		return [self commitFailedBecause:@"Could not create a commit object"];

	if (![repository executeHook:@"pre-commit" output:nil])
		return [self commitFailedBecause:@"Pre-commit hook failed"];

	if (![repository executeHook:@"commit-msg" withArgs:[NSArray arrayWithObject:commitMessageFile] output:nil])
    return [self commitFailedBecause:@"Commit-msg hook failed"];

	[repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-m", commitSubject, @"HEAD", commit, nil]
						  retValue: &ret];
	if (ret)
		return [self commitFailedBecause:@"Could not update HEAD"];

	if (![repository executeHook:@"post-commit" output:nil])
		[webController setStateMessage:[NSString stringWithFormat:@"Post-commit hook failed, however, successfully created commit %@", commit]];
	else
		[webController setStateMessage:[NSString stringWithFormat:@"Successfully created commit %@", commit]];

	repository.hasChanged = YES;
	self.busy--;
	[commitMessageView setString:@""];
	amend = NO;
	amendEnvironment = nil;
	[self refresh:self];
	self.amend = NO;
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
