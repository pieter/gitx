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

@synthesize files, status, busy;

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.busy = 0;

	[unstagedButtonCell setAction:@selector(rowClicked:)];
	[cachedButtonCell setAction:@selector(rowClicked:)];

	[unstagedTable setDoubleAction:@selector(tableClicked:)];
	[cachedTable setDoubleAction:@selector(tableClicked:)];

	[self refresh:self];

	[commitMessageView setTypingAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Monaco" size:12.0] forKey:NSFontAttributeName]];
	
	[unstagedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"cached == 0"]];
	[cachedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"cached == 1"]];
	
	[unstagedFilesController setSortDescriptors:[NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"status" ascending:false],
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true], nil]];
	[cachedFilesController setSortDescriptors:[NSArray arrayWithObject:
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true]]];
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
	id a = [repository parseReference:@"HEAD"];

	// TODO: parseReference should exit nil if it errors out. For
	// now, compare to "HEAD"
	if ([a isEqualToString:@"HEAD"]) {
		// We don't have a head ref. Return the empty tree.
		return @"4b825dc642cb6eb9a060e54bf8d69288fbee4904";
	}

	return @"HEAD";
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
}

- (void) readOtherFiles:(NSNotification *)notification;
{
	NSArray *lines = [self linesFromNotification:notification];
	for (NSString *line in lines) {
		if ([line length] == 0)
			continue;
		PBChangedFile *file =[[PBChangedFile alloc] initWithPath:line andRepository:repository];
		file.status = NEW;
		file.cached = NO;
		[unstagedFilesController addObject:file];
	}
	[self doneProcessingIndex];
}

- (void) readUnstagedFiles:(NSNotification *)notification
{
	NSArray *lines = [self linesFromNotification:notification];
	NSArray *fileStatus;
	int even = 0;
	for (NSString *line in lines) {
		if (!even) {
			even = 1;
			fileStatus = [line componentsSeparatedByString:@" "];
			continue;
		}
		even = 0;
		
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:line andRepository:repository];
		if ([[fileStatus objectAtIndex:4] isEqualToString:@"D"])
			file.status = DELETED;
		else
			file.status = MODIFIED;

		file.cached = NO;

		// FIXME: If you are in a merge and have conflicts, a file is displayed twice, with different
		// index values. For now, we don't handle this gracefully.
		BOOL fileExists = NO;
		for (PBChangedFile *object in [unstagedFilesController arrangedObjects]) {
			if ([[object path] isEqualToString:[file path]]) {
				fileExists = YES;
				break;
			}
		}
		if (!fileExists)
			[unstagedFilesController addObject: file];
	}
	[self doneProcessingIndex];
}

- (void) readCachedFiles:(NSNotification *)notification
{
	NSArray *lines = [self linesFromNotification:notification];
	NSLog(@"Reading cached files!");
	NSArray *fileStatus;
	int even = 0;
	for (NSString *line in lines) {
		if (!even) {
			even = 1;
			fileStatus = [line componentsSeparatedByString:@" "];
			continue;
		}
		even = 0;
		
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:line andRepository:repository];
		if ([[fileStatus objectAtIndex:4] isEqualToString:@"D"])
			file.status = DELETED;
		else
			file.status = MODIFIED;
		
		file.cached = YES;
		[cachedFilesController addObject: file];
	}
	self.files = files;
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
	if ([repository parseSymbolicReference:@"HEAD"]) {
		[arguments addObject:@"-p"];
		[arguments addObject:@"HEAD"];
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
	[self refresh:self];
}

- (void) tableClicked:(NSTableView *) tableView
{
	NSUInteger selectionIndex = [[tableView selectedRowIndexes] firstIndex];
	NSArrayController *controller, *otherController;
	if ([tableView tag] == 0) {
		controller = unstagedFilesController;
		otherController = cachedFilesController;
	}
	else {
		controller = cachedFilesController;
		otherController = unstagedFilesController;
	}
	
	PBChangedFile *selectedItem = [[controller arrangedObjects] objectAtIndex:selectionIndex];
	[controller removeObject:selectedItem];
	if (selectedItem.cached == NO)
		[selectedItem stageChanges];
	else
		[selectedItem unstageChanges];

	// Add the file to the other controller if it's not there yet
	for (PBChangedFile *object in [otherController arrangedObjects])
		if ([[object path] isEqualToString:[selectedItem path]])
			return;

	[otherController addObject:selectedItem];	
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
@end
