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
#import "PBGitIndex.h"
#import "PBGitCommitController.h"

#define FileChangesTableViewType @"GitFileChangedType"

@interface PBGitIndexController ()

@property (weak) IBOutlet PBGitCommitController *commitController;

@end

// FIXME: This isn't a view/window/whatever controller, though it acts like one...
// See for example -menuForTable and its setTarget: calls.
@implementation PBGitIndexController

@synthesize commitController=commitController;
@synthesize stagedFilesController=stagedFilesController;
@synthesize unstagedFilesController=unstagedFilesController;
@synthesize stagedTable=stagedTable;
@synthesize unstagedTable=unstagedTable;

- (void)awakeFromNib
{
	[unstagedTable setDoubleAction:@selector(tableClicked:)];
	[stagedTable setDoubleAction:@selector(tableClicked:)];

	[unstagedTable setTarget:self];
	[stagedTable setTarget:self];

	[unstagedTable registerForDraggedTypes: [NSArray arrayWithObject:FileChangesTableViewType]];
	[stagedTable registerForDraggedTypes: [NSArray arrayWithObject:FileChangesTableViewType]];
}

# pragma mark Context Menu methods
- (BOOL) allSelectedCanBeIgnored:(NSArray *)selectedFiles
{
	if ([selectedFiles count] == 0)
	{
		return NO;
	}
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
	NSArrayController *controller = table.tag == 0 ? unstagedFilesController : stagedFilesController;
	NSArray *selectedFiles = controller.selectedObjects;
	
	NSUInteger numberOfSelectedFiles = selectedFiles.count;

	if (numberOfSelectedFiles == 0)
	{
		return menu;
	}
	
	// Stage/Unstage changes
	if (table.tag == 0) {
		NSString *stageTitle = numberOfSelectedFiles == 1
			? [NSString stringWithFormat:NSLocalizedString( @"Stage “%@”", @"Stage single file contextual menu item" ), [self getNameOfFirstSelectedFile:selectedFiles]]
			: [NSString stringWithFormat:NSLocalizedString( @"Stage %i Files", @"Stage multiple files contextual menu item"), numberOfSelectedFiles ];
		NSMenuItem *stageItem = [[NSMenuItem alloc] initWithTitle:stageTitle action:@selector(stageFilesAction:) keyEquivalent:@"s"];
		stageItem.target = self;
		[menu addItem:stageItem];
	}
	else if (table.tag == 1) {
		NSString *stageTitle = numberOfSelectedFiles == 1
			? [NSString stringWithFormat:NSLocalizedString( @"Unstage “%@”", @"Unstage single file contextual menu item" ), [self getNameOfFirstSelectedFile:selectedFiles]]
			: [NSString stringWithFormat:NSLocalizedString( @"Unstage %i Files", @"Unstage multiple files contextual menu item"), numberOfSelectedFiles ];
		NSMenuItem *unstageItem = [[NSMenuItem alloc] initWithTitle:stageTitle action:@selector(unstageFilesAction:) keyEquivalent:@"u"];
		unstageItem.target = self;
		[menu addItem:unstageItem];
	}

	NSString *openTitle = numberOfSelectedFiles == 1
		? [NSString stringWithFormat:NSLocalizedString( @"Open ”%@“", @"Open single file contextual menu item" ), [self getNameOfFirstSelectedFile:selectedFiles]]
		: [NSString stringWithFormat:NSLocalizedString( @"Open %i Files", @"Open multiple files contextual menu item"), numberOfSelectedFiles ];
	NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:openTitle action:@selector(openFilesAction:) keyEquivalent:@""];
	openItem.target = self;
	[menu addItem:openItem];

	// Attempt to ignore
	if ([self allSelectedCanBeIgnored:selectedFiles]) {
		NSString *ignoreText = numberOfSelectedFiles == 1
			? [NSString stringWithFormat:NSLocalizedString( @"Ignore ”%@“", @"Ignore single file contextual menu item" ), [self getNameOfFirstSelectedFile:selectedFiles]]
			: [NSString stringWithFormat:NSLocalizedString( @"Ignore %i Files", @"Ignore multiple files contextual menu item"), numberOfSelectedFiles ];
		NSMenuItem *ignoreItem = [[NSMenuItem alloc] initWithTitle:ignoreText action:@selector(ignoreFilesAction:) keyEquivalent:@""];
		ignoreItem.target = self;
		[menu addItem:ignoreItem];
	}

	if (numberOfSelectedFiles == 1) {
		NSMenuItem *showInFinderItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Show in Finder", @"Show in Finder contextual menu item") action:@selector(showInFinderAction:) keyEquivalent:@""];
		showInFinderItem.target = self;
		[menu addItem:showInFinderItem];
    }

	BOOL addDiscardMenu = NO;
	for (PBChangedFile *file in selectedFiles)
	{
		if (file.hasUnstagedChanges)
		{
			addDiscardMenu = YES;
			break;
		}
	}

	if (addDiscardMenu)
    {
        NSMenuItem *discardItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Discard changes…", @"Discard changes contextual menu item (will ask for confirmation)") action:@selector(discardFilesAction:) keyEquivalent:@""];
        [discardItem setAlternate:NO];
        [discardItem setTarget:self];

        [menu addItem:discardItem];

        NSMenuItem *discardForceItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Discard changes",  @"Force Discard changes contextual menu item (will NOT ask for confirmation)") action:@selector(forceDiscardFilesAction:) keyEquivalent:@""];
        [discardForceItem setAlternate:YES];
        [discardForceItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [discardForceItem setTarget:self];
        [menu addItem:discardForceItem];
	
        BOOL trashInsteadOfDiscard = floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7;
        if (trashInsteadOfDiscard)
        {
            for (PBChangedFile* file in selectedFiles)
            {
                if (file.status != NEW)
                {
                    trashInsteadOfDiscard = NO;
                    break;
                }
            }
        }

        if (trashInsteadOfDiscard && [selectedFiles count] > 0)
        {
            NSMenuItem* moveToTrashItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Move to Trash", @"Move to Trash contextual menu item") action:@selector(moveToTrashAction:) keyEquivalent:@""];
            [moveToTrashItem setTarget:self];
            [menu addItem:moveToTrashItem];

            [menu removeItem:discardItem];
            [menu removeItem:discardForceItem];
        }
    }

    for (NSMenuItem *item in [menu itemArray]) {
        [item setRepresentedObject:selectedFiles];
    }

	return menu;
}

- (NSString *) getNameOfFirstSelectedFile:(NSArray<PBChangedFile *> *) selectedFiles {
	return selectedFiles.firstObject.path.lastPathComponent;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([self respondsToSelector:[menuItem action]])
        return YES;

    if ([commitController respondsToSelector:[menuItem action]])
        return YES;

    return [[commitController nextResponder] validateMenuItem:menuItem];
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
	if ([tableView tag] == 0) {
		[commitController.index stageFiles:files];
	}
	else {
		[commitController.index unstageFiles:files];
	}
}

- (void) rowClicked:(NSCell *)sender
{
	NSTableView *tableView = (NSTableView *)[sender controlView];
	if([tableView numberOfSelectedRows] != 1)
		return;
	[self tableClicked: tableView];
}

- (BOOL) tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    [pboard declareTypes:[NSArray arrayWithObjects:FileChangesTableViewType, NSFilenamesPboardType, nil] owner:self];

	// Internal, for dragging from one tableview to the other
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:data forType:FileChangesTableViewType];

	// External, to drag them to for example XCode or Textmate
	NSArrayController *controller = [tv tag] == 0 ? unstagedFilesController : stagedFilesController;
	NSArray *files = [controller.arrangedObjects objectsAtIndexes:rowIndexes];
	NSURL *workingDirectoryURL = commitController.repository.workingDirectoryURL;

	NSMutableArray<NSURL *> *URLs = [NSMutableArray arrayWithCapacity:rowIndexes.count];
	for (PBChangedFile *file in files) {
		[URLs addObject:[workingDirectoryURL URLByAppendingPathComponent:file.path]];
	}
	[pboard writeObjects:URLs];
	
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

	if ([aTableView tag] == 0) {
		[commitController.index unstageFiles:files];
	}
	else {
		[commitController.index stageFiles:files];
	}

	return YES;
}

# pragma mark Key View Chain

-(NSView *)nextKeyViewFor:(NSView *)view
{
    return [commitController nextKeyViewFor:view];
}

-(NSView *)previousKeyViewFor:(NSView *)view
{
    return [commitController previousKeyViewFor:view];
}

@end
