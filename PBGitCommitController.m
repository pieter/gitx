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

@implementation PBGitCommitController

@synthesize files, status, busy, amend;

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.busy = 0;

	amend = NO;

	[unstagedButtonCell setAction:@selector(rowClicked:)];
	[cachedButtonCell setAction:@selector(rowClicked:)];

	[unstagedTable setDoubleAction:@selector(tableClicked:)];
	[cachedTable setDoubleAction:@selector(tableClicked:)];

	[unstagedTable setController: self];

	[self refresh:self];

	[commitMessageView setTypingAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Monaco" size:12.0] forKey:NSFontAttributeName]];
	
	[unstagedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"hasUnstagedChanges == 1"]];
	[cachedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"hasCachedChanges == 1"]];
	
	[unstagedFilesController setSortDescriptors:[NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"status" ascending:false],
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true], nil]];
	[cachedFilesController setSortDescriptors:[NSArray arrayWithObject:
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true]]];
}

- (void) setAmend:(BOOL)newAmend
{
	if (newAmend == amend)
		return;
	amend = newAmend;

	if (amend && [[commitMessageView string] length] <= 3)
		commitMessageView.string = [repository outputForCommand:@"log -1 --pretty=format:%s%n%n%b HEAD"];

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

	NSString *a = [repository parseReference:@"HEAD^"];

	// TODO: parseReference should exit nil if it errors out. For
	// now, compare to "HEAD"
	if ([a isEqualToString:parent]) {
		// We don't have a head ref. Return the empty tree.
		return @"4b825dc642cb6eb9a060e54bf8d69288fbee4904";
	}

	return parent;
}

- (void) refresh:(id) sender
{
	self.status = @"Refreshing index…";
	self.busy++;
	self.files = [NSMutableArray array];

	[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"update-index", @"-q", @"--unmerged", @"--ignore-missing", @"--refresh", nil]];
	self.busy--;

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; 
	[nc removeObserver:self]; 

	// Other files
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

	// Cached files
	handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObjects:@"diff-index", @"--cached", @"-z", [self parentTree], nil]];
	[nc addObserver:self selector:@selector(readCachedFiles:) name:NSFileHandleReadToEndOfFileCompletionNotification object:handle]; 
	self.busy++;
	[handle readToEndOfFileInBackgroundAndNotify];
	
	self.files = files;
}

- (void) doneProcessingIndex
{
	if (!--self.busy)
		self.status = @"Ready";
	[unstagedFilesController didChangeArrangementCriteria];
	[cachedFilesController didChangeArrangementCriteria];
}

- (void) readOtherFiles:(NSNotification *)notification;
{
	NSArray *lines = [self linesFromNotification:notification];
	for (NSString *line in lines) {
		if ([line length] == 0)
			continue;
		PBChangedFile *file =[[PBChangedFile alloc] initWithPath:line andRepository:repository];
		file.status = NEW;
		file.hasCachedChanges = NO;
		file.hasUnstagedChanges = YES;

		[files addObject: file];
	}
	[self doneProcessingIndex];
}

- (void) addFilesFromLines:(NSArray *)lines cached:(BOOL) cached
{
	NSArray *fileStatus;
	int even = 0;
	for (NSString *line in lines) {
		if (!even) {
			even = 1;
			fileStatus = [line componentsSeparatedByString:@" "];
			continue;
		}
		even = 0;

		BOOL isNew = YES;
		// If the file is already added, we shouldn't add it again
		// but rather update it to incorporate our changes
		for (PBChangedFile *file in files) {
			if ([file.path isEqualToString:line]) {
				if (cached)
					file.hasCachedChanges = YES;
				else
					file.hasUnstagedChanges = YES;
				isNew = NO;
				break;
			}
		}

		if (!isNew)
			continue;

		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:line andRepository:repository];
		if ([[fileStatus objectAtIndex:4] isEqualToString:@"D"])
			file.status = DELETED;
		else
			file.status = MODIFIED;

		file.hasCachedChanges = cached;
		file.hasUnstagedChanges = !cached;

		[files addObject: file];
	}

}

- (void) readUnstagedFiles:(NSNotification *)notification
{
	NSArray *lines = [self linesFromNotification:notification];
	[self addFilesFromLines:lines cached:NO];
	[self doneProcessingIndex];
}

- (void) readCachedFiles:(NSNotification *)notification
{
	NSArray *lines = [self linesFromNotification:notification];
	[self addFilesFromLines:lines cached:YES];
	[self doneProcessingIndex];
}

- (void) commitFailedBecause:(NSString *)reason
{
	self.busy--;
	self.status = [@"Commit failed: " stringByAppendingString:reason];
	[[NSAlert alertWithMessageText:@"Commit failed"
					 defaultButton:nil
				   alternateButton:nil
					   otherButton:nil
		 informativeTextWithFormat:reason] runModal];
	return;
}

- (IBAction) commit:(id) sender
{
	if ([[cachedFilesController arrangedObjects] count] == 0) {
		[[NSAlert alertWithMessageText:@"No changes to commit"
						 defaultButton:nil
					   alternateButton:nil
						   otherButton:nil
			 informativeTextWithFormat:@"You must first stage some changes before committing"] runModal];
		return;
	}		
	
	NSString *commitMessage = [commitMessageView string];
	if ([commitMessage length] < 3) {
		[[NSAlert alertWithMessageText:@"Commitmessage missing"
						 defaultButton:nil
					   alternateButton:nil
						   otherButton:nil
			 informativeTextWithFormat:@"Please enter a commit message before committing"] runModal];
		return;
	}

	NSString *commitSubject;
	NSRange newLine = [commitMessage rangeOfString:@"\n"];
	if (newLine.location == NSNotFound)
		commitSubject = commitMessage;
	else
		commitSubject = [commitMessage substringToIndex:newLine.location];
	
	commitSubject = [@"commit: " stringByAppendingString:commitSubject];

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
											 retValue: &ret];

	if (ret || [commit length] != 40)
		return [self commitFailedBecause:@"Could not create a commit object"];
	
	[repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-m", commitSubject, @"HEAD", commit, nil]
						  retValue: &ret];
	if (ret)
		return [self commitFailedBecause:@"Could not update HEAD"];

	[[NSAlert alertWithMessageText:@"Commit succesful"
					 defaultButton:nil
				   alternateButton:nil
					   otherButton:nil
		 informativeTextWithFormat:@"Successfully created commit %@", commit] runModal];
	
	repository.hasChanged = YES;
	self.busy--;
	[commitMessageView setString:@""];
	amend = NO;
	[self refresh:self];
	self.amend = NO;
}

- (void) tableClicked:(NSTableView *) tableView
{
	NSUInteger selectionIndex = [[tableView selectedRowIndexes] firstIndex];
	NSArrayController *controller = [tableView tag] == 0 ? unstagedFilesController : cachedFilesController;
	PBChangedFile *selectedItem = [[controller arrangedObjects] objectAtIndex:selectionIndex];

	if ([tableView tag] == 0)
		[selectedItem stageChanges];
	else
		[selectedItem unstageChangesAmend:amend];

}

- (void) rowClicked:(NSCell *)sender
{
	NSTableView *tableView = (NSTableView *)[sender controlView];
	if([tableView numberOfSelectedRows] != 1)
		return;
	[self tableClicked: tableView];
}

- (void)tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
	[[tableColumn dataCell] setImage:[[[(([tableView tag] == 0) ? unstagedFilesController : cachedFilesController) arrangedObjects] objectAtIndex:rowIndex] icon]];
}

- (NSMenu *) menuForTable:(NSTableView *)table
{
	NSUInteger selectionIndex = [[table selectedRowIndexes] firstIndex];
	PBChangedFile *selectedItem = [[unstagedFilesController arrangedObjects] objectAtIndex:selectionIndex];

	NSMenu *a = [[NSMenu alloc] init];
	NSMenuItem *stageItem = [[NSMenuItem alloc] initWithTitle:@"Stage Changes" action:@selector(stageChanges) keyEquivalent:@""];
	[stageItem setTarget:selectedItem];
	[a addItem:stageItem];

	// Do not add "revert" options for untracked files
	if (selectedItem.status == NEW)
		return a;

	NSMenuItem *revertItem = [[NSMenuItem alloc] initWithTitle:@"Revert Changes…" action:@selector(revertChanges) keyEquivalent:@""];
	[revertItem setTarget:selectedItem];
	[revertItem setAlternate:NO];
	[a addItem:revertItem];

	NSMenuItem *revertForceItem = [[NSMenuItem alloc] initWithTitle:@"Revert Changes" action:@selector(forceRevertChanges) keyEquivalent:@""];
	[revertForceItem setTarget:selectedItem];
	[revertForceItem setAlternate:YES];
	[revertForceItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[a addItem:revertForceItem];

	return a;
}

- (void) stageHunk:(NSString *)hunk reverse:(BOOL)reverse
{
	NSMutableArray *array = [NSMutableArray arrayWithObjects:@"apply", @"--cached", nil];
	if (reverse)
		[array addObject:@"--reverse"];

	int ret;
	NSString *error = [repository outputForArguments:array
										 inputString:hunk
											retValue: &ret];
	if (ret)
		NSLog(@"Error: %@", error);
	[self refresh:self]; // TODO: We should do this smarter by checking if the file diff is empty, which is faster.
}
@end
