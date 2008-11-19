//
//  PBGitIndexController.m
//  GitX
//
//  Created by Pieter de Bie on 18-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBGitIndexController.h"
#import "PBChangedFile.h"

#define FileChangesTableViewType @"GitFileChangedType"

@implementation PBGitIndexController

- (void)awakeFromNib
{
	[unstagedTable setDoubleAction:@selector(tableClicked:)];
	[stagedTable setDoubleAction:@selector(tableClicked:)];

	[unstagedTable setTarget:self];
	[stagedTable setTarget:self];

	[unstagedTable registerForDraggedTypes: [NSArray arrayWithObject:FileChangesTableViewType]];
	[stagedTable registerForDraggedTypes: [NSArray arrayWithObject:FileChangesTableViewType]];

}

- (void) stageFiles:(NSArray *)files
{
	NSMutableString *input = [NSMutableString string];

	for (PBChangedFile *file in files) {
		[input appendFormat:@"%@\0", file.path];
	}

	int ret = 1;
	[commitController.repository outputForArguments:[NSArray arrayWithObjects:@"update-index", @"--add", @"--remove", @"-z", @"--stdin", nil]
	 inputString:input retValue:&ret];

	if (ret)
	{
		NSLog(@"Error when updating index. Retvalue: %i", ret);
		return;
	}

	for (PBChangedFile *file in files)
	{
		file.hasUnstagedChanges = NO;
		file.hasCachedChanges = YES;
	}
}

- (void) unstageFiles:(NSArray *)files
{
	NSMutableString *input = [NSMutableString string];
	
	for (PBChangedFile *file in files) {
		[input appendString:[file indexInfo]];
	}

	int ret = 1;
	[commitController.repository outputForArguments:[NSArray arrayWithObjects:@"update-index", @"-z", @"--index-info", nil]
	 inputString:input retValue:&ret];
	
	if (ret)
	{
		NSLog(@"Error when updating index. Retvalue: %i", ret);
		return;
	}
	
	for (PBChangedFile *file in files)
	{
		file.hasUnstagedChanges = YES;
		file.hasCachedChanges = NO;
	}
}

# pragma mark Displaying diffs

- (NSString *) stagedChangesForFile:(PBChangedFile *)file
{
	NSString *indexPath = [@":0:" stringByAppendingString:file.path];

	if (file.status == NEW)
		return [commitController.repository outputForArguments:[NSArray arrayWithObjects:@"show", indexPath, nil]];

	return [commitController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", file.commitBlobSHA, indexPath, nil]];
}

- (NSString *)unstagedChangesForFile:(PBChangedFile *)file
{
	if (file.status == NEW) {
		NSStringEncoding encoding;
		NSError *error = nil;
		NSString *contents = [NSString stringWithContentsOfFile:[[commitController.repository workingDirectory] stringByAppendingPathComponent:file.path]
												   usedEncoding:&encoding error:&error];
		if (error)
			return nil;

		return contents;
	}

	return [commitController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", @"--", file.path, nil]];
}

//- (void) forceRevertChanges
//{
//	[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"checkout", @"--", file.path, nil]];
//	self.hasUnstagedChanges = NO;
//}
//
//- (void) revertChanges
//{
//	int ret = [[NSAlert alertWithMessageText:@"Revert changes"
//					 defaultButton:nil
//				   alternateButton:@"Cancel"
//					   otherButton:nil
//		 informativeTextWithFormat:@"Are you sure you wish to revert the changes in '%@'?\n\n You cannot undo this operation.", path] runModal];	
//
//	if (ret == NSAlertDefaultReturn)
//		[self forceRevertChanges];
//}


# pragma mark Context Menu methods
- (NSMenu *) menuForTable:(NSTableView *)table
{
	NSMenu *menu = [[NSMenu alloc] init];
	id controller = [table tag] == 0 ? unstagedFilesController : stagedFilesController;
	NSArray *selectedFiles = [controller selectedObjects];

	// Unstaged changes
	if ([table tag] == 0) {
		NSMenuItem *stageItem = [[NSMenuItem alloc] initWithTitle:@"Stage Changes" action:@selector(stageFilesAction:) keyEquivalent:@""];
		[stageItem setTarget:self];
		[stageItem setRepresentedObject:selectedFiles];
		[menu addItem:stageItem];
	}
	else if ([table tag] == 1) {
		NSMenuItem *unstageItem = [[NSMenuItem alloc] initWithTitle:@"Unstage Changes" action:@selector(unstageFilesAction:) keyEquivalent:@""];
		[unstageItem setTarget:self];
		[unstageItem setRepresentedObject:selectedFiles];
		[menu addItem:unstageItem];
	}

	NSString *title = [selectedFiles count] == 1 ? @"Open file" : @"Open files";
	NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(openFilesAction:) keyEquivalent:@""];
	[openItem setTarget:self];
	[openItem setRepresentedObject:selectedFiles];
	[menu addItem:openItem];

	
	// Do not add "revert" options for untracked files
	//	if (selectedItem.status == NEW)
	//		return a;
	//
	//	NSMenuItem *revertItem = [[NSMenuItem alloc] initWithTitle:@"Revert Changes…" action:@selector(revertChanges) keyEquivalent:@""];
	//	[revertItem setTarget:selectedItem];
	//	[revertItem setAlternate:NO];
	//	[a addItem:revertItem];
	//
	//	NSMenuItem *revertForceItem = [[NSMenuItem alloc] initWithTitle:@"Revert Changes" action:@selector(forceRevertChanges) keyEquivalent:@""];
	//	[revertForceItem setTarget:selectedItem];
	//	[revertForceItem setAlternate:YES];
	//	[revertForceItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	//	[a addItem:revertForceItem];
	
	return menu;
}

- (void) stageFilesAction:(id) sender
{
	[self stageFiles:[sender representedObject]];
}

- (void) unstageFilesAction:(id) sender
{
	[self unstageFiles:[sender representedObject]];
}

- (void) openFilesAction:(id) sender
{
	NSArray *files = [sender representedObject];
	NSString *workingDirectory = [commitController.repository workingDirectory];
	for (PBChangedFile *file in files)
		[[NSWorkspace sharedWorkspace] openFile:[workingDirectory stringByAppendingPathComponent:[file path]]];
}

# pragma mark TableView icon delegate
- (void)tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(int)rowIndex
{
	id controller = [tableView tag] == 0 ? unstagedFilesController : stagedFilesController;
	[[tableColumn dataCell] setImage:[[[controller arrangedObjects] objectAtIndex:rowIndex] icon]];
}

- (void) tableClicked:(NSTableView *) tableView
{
	NSArrayController *controller = [tableView tag] == 0 ? unstagedFilesController : stagedFilesController;

	NSIndexSet *selectionIndexes = [tableView selectedRowIndexes];
	NSArray *files = [[controller arrangedObjects] objectsAtIndexes:selectionIndexes];
	if ([tableView tag] == 0)
		[self stageFiles:files];
	else
		[self unstageFiles:files];
}

- (void) rowClicked:(NSCell *)sender
{
	NSTableView *tableView = (NSTableView *)[sender controlView];
	if([tableView numberOfSelectedRows] != 1)
		return;
	[self tableClicked: tableView];
}

- (BOOL)tableView:(NSTableView *)tv
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
	 toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    [pboard declareTypes:[NSArray arrayWithObjects:FileChangesTableViewType, NSFilenamesPboardType, nil] owner:self];

	// Internal, for dragging from one tableview to the other
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:data forType:FileChangesTableViewType];

	// External, to drag them to for example XCode or Textmate
	NSArrayController *controller = [tv tag] == 0 ? unstagedFilesController : stagedFilesController;
	NSArray *files = [[controller arrangedObjects] objectsAtIndexes:rowIndexes];
	NSString *workingDirectory = [commitController.repository workingDirectory];

	NSMutableArray *filenames = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	for (PBChangedFile *file in files)
		[filenames addObject:[workingDirectory stringByAppendingPathComponent:[file path]]];

	[pboard setPropertyList:filenames forType:NSFilenamesPboardType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([info draggingSource] == tableView)
		return NSDragOperationNone;

	[tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:FileChangesTableViewType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];

	NSArrayController *controller = [aTableView tag] == 0 ? stagedFilesController : unstagedFilesController;
	NSArray *files = [[controller arrangedObjects] objectsAtIndexes:rowIndexes];

	if ([aTableView tag] == 0)
		[self unstageFiles:files];
	else
		[self stageFiles:files];

	return YES;
}

# pragma mark WebKit Accessibility

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

@end
