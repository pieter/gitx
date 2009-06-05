//
//  PBGitIndexController.m
//  GitX
//
//  Created by Pieter de Bie on 18-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBGitIndexController.h"
#import "PBChangedFile.h"
#import "PBGitRepository.h"

#define FileChangesTableViewType @"GitFileChangedType"

@interface PBGitIndexController (PrivateMethods)
- (void)stopTrackingIndex;
- (void)resumeTrackingIndex;
@end

@implementation PBGitIndexController

@synthesize contextSize;

- (void)awakeFromNib
{
	contextSize = 3;

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

	[self stopTrackingIndex];
	for (PBChangedFile *file in files)
	{
		file.hasUnstagedChanges = NO;
		file.hasStagedChanges = YES;
	}
	[self resumeTrackingIndex];
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

	[self stopTrackingIndex];
	for (PBChangedFile *file in files)
	{
		file.hasUnstagedChanges = YES;
		file.hasStagedChanges = NO;
	}
	[self resumeTrackingIndex];
}

- (void) ignoreFiles:(NSArray *)files
{
	// Build output string
	NSMutableArray *fileList = [NSMutableArray array];
	for (PBChangedFile *file in files) {
		NSString *name = file.path;
		if ([name length] > 0)
			[fileList addObject:name];
	}
	NSString *filesAsString = [fileList componentsJoinedByString:@"\n"];

	// Write to the file
	NSString *gitIgnoreName = [commitController.repository gitIgnoreFilename];

	NSStringEncoding enc = NSUTF8StringEncoding;
	NSError *error = nil;
	NSMutableString *ignoreFile;

	if (![[NSFileManager defaultManager] fileExistsAtPath:gitIgnoreName]) {
		ignoreFile = [filesAsString mutableCopy];
	} else {
		ignoreFile = [NSMutableString stringWithContentsOfFile:gitIgnoreName usedEncoding:&enc error:&error];
		if (error) {
			[[commitController.repository windowController] showErrorSheet:error];
			return;
		}
		// Add a newline if not yet present
		if ([ignoreFile characterAtIndex:([ignoreFile length] - 1)] != '\n')
			[ignoreFile appendString:@"\n"];
		[ignoreFile appendString:filesAsString];
	}

	[ignoreFile writeToFile:gitIgnoreName atomically:YES encoding:enc error:&error];
	if (error)
		[[commitController.repository windowController] showErrorSheet:error];
}

# pragma mark Displaying diffs

- (NSString *) stagedChangesForFile:(PBChangedFile *)file
{
	NSString *indexPath = [@":0:" stringByAppendingString:file.path];

	if (file.status == NEW)
		return [commitController.repository outputForArguments:[NSArray arrayWithObjects:@"show", indexPath, nil]];

	return [commitController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff-index", [self contextParameter], @"--cached", [commitController parentTree], @"--", file.path, nil]];
}

- (NSString *)unstagedChangesForFile:(PBChangedFile *)file
{
	if (file.status == NEW) {
		NSStringEncoding encoding;
		NSError *error = nil;
		NSString *path = [[commitController.repository workingDirectory] stringByAppendingPathComponent:file.path];
		NSString *contents = [NSString stringWithContentsOfFile:path
												   usedEncoding:&encoding
														  error:&error];
		if (error)
			return nil;

		return contents;
	}

	return [commitController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff-files", [self contextParameter], @"--", file.path, nil]];
}

- (void) forceRevertChangesForFiles:(NSArray *)files
{
	NSArray *paths = [files valueForKey:@"path"];
	NSString *input = [paths componentsJoinedByString:@"\0"];

	NSArray *arguments = [NSArray arrayWithObjects:@"checkout-index", @"--index", @"--quiet", @"--force", @"-z", @"--stdin", nil];
	int ret = 1;
	[commitController.repository outputForArguments:arguments inputString:input retValue:&ret];
	if (ret) {
		[[commitController.repository windowController] showMessageSheet:@"Reverting changes failed" infoText:[NSString stringWithFormat:@"Reverting changes failed with error code %i", ret]];
		return;
	}

	for (PBChangedFile *file in files)
		file.hasUnstagedChanges = NO;
}

- (void) revertChangesForFiles:(NSArray *)files
{
	int ret = [[NSAlert alertWithMessageText:@"Revert changes"
					 defaultButton:nil
				   alternateButton:@"Cancel"
					   otherButton:nil
		 informativeTextWithFormat:@"Are you sure you wish to revert changes?\n\n You cannot undo this operation."] runModal];

	if (ret == NSAlertDefaultReturn)
		[self forceRevertChangesForFiles:files];
}


# pragma mark Context Menu methods
- (BOOL) allSelectedCanBeIgnored:(NSArray *)selectedFiles
{
	for (PBChangedFile *selectedItem in selectedFiles) {
		if (selectedItem.status != NEW) {
			return NO;
		}
	}
	return YES;
}

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

	// Attempt to ignore
	if ([self allSelectedCanBeIgnored:selectedFiles]) {
		NSString *ignoreText = [selectedFiles count] == 1 ? @"Ignore File": @"Ignore Files";
		NSMenuItem *ignoreItem = [[NSMenuItem alloc] initWithTitle:ignoreText action:@selector(ignoreFilesAction:) keyEquivalent:@""];
		[ignoreItem setTarget:self];
		[ignoreItem setRepresentedObject:selectedFiles];
		[menu addItem:ignoreItem];
	}

	if ([selectedFiles count] == 1) {
		NSMenuItem *showInFinderItem = [[NSMenuItem alloc] initWithTitle:@"Show in Finder" action:@selector(showInFinderAction:) keyEquivalent:@""];
		[showInFinderItem setTarget:self];
		[showInFinderItem setRepresentedObject:selectedFiles];
		[menu addItem:showInFinderItem];
    }

	for (PBChangedFile *file in selectedFiles)
		if (!file.hasUnstagedChanges)
			return menu;

	NSMenuItem *revertItem = [[NSMenuItem alloc] initWithTitle:@"Revert Changes…" action:@selector(revertFilesAction:) keyEquivalent:@""];
	[revertItem setTarget:self];
	[revertItem setAlternate:NO];
	[revertItem setRepresentedObject:selectedFiles];

	[menu addItem:revertItem];

	NSMenuItem *revertForceItem = [[NSMenuItem alloc] initWithTitle:@"Revert Changes" action:@selector(forceRevertFilesAction:) keyEquivalent:@""];
	[revertForceItem setTarget:self];
	[revertForceItem setAlternate:YES];
	[revertForceItem setRepresentedObject:selectedFiles];
	[revertForceItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
	[menu addItem:revertForceItem];
	
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

- (void) ignoreFilesAction:(id) sender
{
	NSArray *selectedFiles = [sender representedObject];
	if ([selectedFiles count] > 0) {
		[self ignoreFiles:selectedFiles];
	}
	[commitController refresh:NULL];
}

- (void) revertFilesAction:(id) sender
{
	NSArray *selectedFiles = [sender representedObject];
	if ([selectedFiles count] > 0)
		[self revertChangesForFiles:selectedFiles];
}

- (void) forceRevertFilesAction:(id) sender
{
	NSArray *selectedFiles = [sender representedObject];
	if ([selectedFiles count] > 0)
		[self forceRevertChangesForFiles:selectedFiles];
}

- (void) showInFinderAction:(id) sender
{
	NSArray *selectedFiles = [sender representedObject];
	if ([selectedFiles count] == 0)
		return;
	NSString *workingDirectory = [[commitController.repository workingDirectory] stringByAppendingString:@"/"];
	NSString *path = [workingDirectory stringByAppendingPathComponent:[[selectedFiles objectAtIndex:0] path]];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	[ws selectFile: path inFileViewerRootedAtPath:nil];
}


# pragma mark TableView icon delegate
- (void)tableView:(NSTableView*)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)rowIndex
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
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([info draggingSource] == tableView)
		return NSDragOperationNone;

	[tableView setDropRow:-1 dropOperation:NSTableViewDropOn];
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
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

- (NSString *) contextParameter
{
	return [[NSString alloc] initWithFormat:@"-U%i", contextSize];
}

# pragma mark WebKit Accessibility

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

#pragma mark Private Methods
- (void)stopTrackingIndex
{
	[stagedFilesController setAutomaticallyRearrangesObjects:NO];
	[unstagedFilesController setAutomaticallyRearrangesObjects:NO];
}
- (void)resumeTrackingIndex
{
	[stagedFilesController setAutomaticallyRearrangesObjects:YES];
	[unstagedFilesController setAutomaticallyRearrangesObjects:YES];
	[stagedFilesController rearrangeObjects];
	[unstagedFilesController rearrangeObjects];
}
@end
