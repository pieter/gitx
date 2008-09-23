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

@synthesize files;

- (void)awakeFromNib
{
	[unstagedButtonCell setAction:@selector(cellClicked:)];
	[cachedButtonCell setAction:@selector(cellClicked:)];

	[self refresh:self];
	
	[unstagedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"cached == 0"]];
	[cachedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"cached == 1"]];
}

- (void) readOtherFiles
{
	NSArray *arguments = [NSArray arrayWithObjects:@"ls-files", @"--others", @"--exclude-standard", nil];
	NSFileHandle *handle = [repository handleInWorkDirForArguments:arguments];
	
	NSString *line;
	while (line = [handle readLine]) {
		if ([line length] == 0)
			break;
		PBChangedFile *file =[[PBChangedFile alloc] initWithPath:line andRepository:repository];
		file.status = NEW;
		file.cached = NO;
		[files addObject: file];
	}
}

- (void) refresh:(id) sender
{
	files = [NSMutableArray array];
	[repository outputForCommand:@"update-index"];
	[self readUnstagedFiles];
	[self readCachedFiles];
	[self readOtherFiles];
	self.files = files;
}

- (void) readUnstagedFiles
{
	NSFileHandle *handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObject:@"diff-files"]];
		
	NSString *line;
	while (line = [handle readLine]) {
		NSArray *components = [line componentsSeparatedByString:@"\t"];
		if ([components count] < 2)
			break;
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:[components objectAtIndex:1] andRepository:repository];
		file.status = MODIFIED;
		file.cached =NO;
		[files addObject: file];
	}
}

- (void) readCachedFiles
{
	NSFileHandle *handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObjects:@"diff-index", @"--cached", @"HEAD", nil]];
	
	NSString *line;
	while (line = [handle readLine]) {
		NSArray *components = [line componentsSeparatedByString:@"\t"];
		if ([components count] < 2)
			break;
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:[components objectAtIndex:1] andRepository:repository];
		file.status = MODIFIED;
		file.cached = YES;
		[files addObject: file];
	}
}

- (IBAction) commit:(id) sender
{
	NSString *commitMessage = [commitMessageView string];
	if ([commitMessage length] < 3) {
		[[NSAlert alertWithMessageText:@"Commitmessage missing"
						 defaultButton:nil
					   alternateButton:nil
						   otherButton:nil
			 informativeTextWithFormat:@"Please enter a commit message before committing"] runModal];
		return;
	}
	
	NSString *tree = [repository outputForCommand:@"write-tree"];
	if ([tree length] != 40) {
		NSLog(@"Tree: %@", tree);
		return;
	}
	int ret;
	NSString *commit = [repository outputForArguments:[NSArray arrayWithObjects:@"commit-tree", tree, @"-p", @"HEAD", nil]
										  inputString:commitMessage
											 retValue: &ret];
	if (ret || [commit length] != 40) {
		NSLog(@"Commit failed");
		return;
	}
	
	[repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-m", @"Commit from GitX", @"HEAD", commit, nil]
						  retValue: &ret];
	if (ret) {
		NSLog(@"Commit failed(2)");
		return;
	}

	NSLog(@"Success! New commit: %@", commit);
}

- (void) cellClicked:(NSCell*) sender
{
	NSTableView* tableView = [sender controlView];
	if([tableView numberOfSelectedRows] == 1)
	{
		NSUInteger selectionIndex = [[tableView selectedRowIndexes] firstIndex];
		PBChangedFile *selectedItem = [[(([tableView tag] == 0) ? unstagedFilesController : cachedFilesController) arrangedObjects] objectAtIndex:selectionIndex];
		if (selectedItem.cached == NO) {
			[selectedItem stageChanges];
			
		}
		else {
			[selectedItem unstageChanges];
		}
		[self refreshControllers];
	
	}
}

- (void) refreshControllers
{
	[self refresh:self];
}
	
- (void)tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
	[[tableColumn dataCell] setImage:[[[(([tableView tag] == 0) ? unstagedFilesController : cachedFilesController) arrangedObjects] objectAtIndex:rowIndex] icon]];
}
@end
