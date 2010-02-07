//
//  PBLabelController.m
//  GitX
//
//  Created by Pieter de Bie on 21-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBRefController.h"
#import "PBGitRevisionCell.h"
#import "PBRefMenuItem.h"
#import "PBCreateBranchSheet.h"
#import "PBCreateTagSheet.h"

@implementation PBRefController

- (void)awakeFromNib
{
	[commitList registerForDraggedTypes:[NSArray arrayWithObject:@"PBGitRef"]];
	[historyController addObserver:self forKeyPath:@"repository.branches" options:0 context:@"branchChange"];
	[historyController addObserver:self forKeyPath:@"repository.currentBranch" options:0 context:@"currentBranchChange"];
	[self updateBranchMenu];
	[self selectCurrentBranch];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(NSString *)context isEqualToString: @"branchChange"]) {
		[commitController rearrangeObjects];
		[self updateBranchMenu];
	}
	else if ([(NSString *)context isEqualToString:@"currentBranchChange"]) {
		[self selectCurrentBranch];
		[commitController rearrangeObjects];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark Fetch

- (void) fetchRemote:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	if ([refish refishType] == kGitXCommitType)
		return;

	[historyController.repository beginFetchFromRemoteForRef:refish];
}


#pragma mark Pull

- (void) pullRemote:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	[historyController.repository beginPullFromRemote:nil forRef:refish];
}


#pragma mark Merge

- (void) merge:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	[historyController.repository mergeWithRefish:refish];
}


#pragma mark Checkout

- (void) checkout:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	[historyController.repository checkoutRefish:refish];
}


#pragma mark Cherry Pick

- (void) cherryPick:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	[historyController.repository cherryPickRefish:refish];
}


#pragma mark Rebase

- (void) rebaseHeadBranch:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	PBGitRef *headRef = [[historyController.repository headRef] ref];

	[historyController.repository rebaseBranch:headRef onRefish:refish];
}


#pragma mark Create Branch

- (void) createBranch:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	[PBCreateBranchSheet beginCreateBranchSheetAtRefish:refish inRepository:historyController.repository];
}


#pragma mark Copy info

- (void) copySHA:(PBRefMenuItem *)sender
{
	PBGitCommit *commit = nil;
	if ([[sender refish] refishType] == kGitXCommitType)
		commit = (PBGitCommit *)[sender refish];
	else
		commit = [historyController.repository commitForRef:[sender refish]];

	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[pasteboard setString:[commit realSha] forType:NSStringPboardType];
}

- (void) copyPatch:(PBRefMenuItem *)sender
{
	PBGitCommit *commit = nil;
	if ([[sender refish] refishType] == kGitXCommitType)
		commit = (PBGitCommit *)[sender refish];
	else
		commit = [historyController.repository commitForRef:[sender refish]];

	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
	[pasteboard setString:[commit patch] forType:NSStringPboardType];
}


#pragma mark Tags

- (void) createTag:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = [sender refish];
	[PBCreateTagSheet beginCreateTagSheetAtRefish:refish inRepository:historyController.repository];
}

- (void) showTagInfoSheet:(PBRefMenuItem *)sender
{
	if ([[sender refish] refishType] != kGitXTagType)
		return;

	NSString *tagName = [(PBGitRef *)[sender refish] tagName];

	int retValue = 1;
	NSArray *args = [NSArray arrayWithObjects:@"tag", @"-n50", @"-l", tagName, nil];
	NSString *info = [historyController.repository outputInWorkdirForArguments:args retValue:&retValue];
	if (!retValue) {
		NSString *message = [NSString stringWithFormat:@"Info for tag: %@", tagName];
		[historyController.repository.windowController showMessageSheet:message infoText:info];
	}
}


#pragma mark Remove a branch, remote or tag

- (void) showDeleteRefSheet:(PBRefMenuItem *)sender
{
	if ([[sender refish] refishType] == kGitXCommitType)
		return;

	PBGitRef *ref = (PBGitRef *)[sender refish];
	NSString *ref_desc = [NSString stringWithFormat:@"%@ '%@'", [ref refishType], [ref shortName]];

	NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Delete %@?", ref_desc]
									 defaultButton:@"Delete"
								   alternateButton:@"Cancel"
									   otherButton:nil
						 informativeTextWithFormat:@"Are you sure you want to remove the %@?", ref_desc];
	
	[alert beginSheetModalForWindow:[historyController.repository.windowController window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteRefSheetDidEnd:returnCode:contextInfo:)
						contextInfo:ref];
}

- (void) deleteRefSheetDidEnd:(NSAlert *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [[sheet window] orderOut:nil];

	if (returnCode == NSAlertDefaultReturn) {
		PBGitRef *ref = (PBGitRef *)contextInfo;
		[historyController.repository deleteRef:ref];
		[commitController rearrangeObjects];
	}
}



#pragma mark Contextual menus

- (NSArray *) menuItemsForRef:(PBGitRef *)ref
{
	return [PBRefMenuItem defaultMenuItemsForRef:ref inRepository:historyController.repository target:self];
}

- (NSArray *) menuItemsForCommit:(PBGitCommit *)commit
{
	return [PBRefMenuItem defaultMenuItemsForCommit:commit target:self];
}


# pragma mark Tableview delegate methods

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSPoint location = [tv convertPointFromBase:[(PBCommitList *)tv mouseDownPoint]];
	int row = [tv rowAtPoint:location];
	int column = [tv columnAtPoint:location];
	int subjectColumn = [tv columnWithIdentifier:@"SubjectColumn"];
	if (column != subjectColumn)
		return NO;
	
	PBGitRevisionCell *cell = (PBGitRevisionCell *)[tv preparedCellAtColumn:column row:row];
	NSRect cellFrame = [tv frameOfCellAtColumn:column row:row];
	
	int index = [cell indexAtX:(location.x - cellFrame.origin.x)];
	
	if (index == -1)
		return NO;
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:row], [NSNumber numberWithInt:index], NULL]];
	[pboard declareTypes:[NSArray arrayWithObject:@"PBGitRef"] owner:self];
	[pboard setData:data forType:@"PBGitRef"];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (operation == NSTableViewDropAbove)
		return NSDragOperationNone;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	if ([pboard dataForType:@"PBGitRef"])
		return NSDragOperationMove;
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)operation
{
	if (operation != NSTableViewDropOn)
		return NO;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *data = [pboard dataForType:@"PBGitRef"];
	if (!data)
		return NO;
	
	NSArray *numbers = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	int oldRow = [[numbers objectAtIndex:0] intValue];
	int oldRefIndex = [[numbers objectAtIndex:1] intValue];
	PBGitCommit *oldCommit = [[commitController arrangedObjects] objectAtIndex: oldRow];
	PBGitRef *ref = [[oldCommit refs] objectAtIndex:oldRefIndex];
	
	PBGitCommit *dropCommit = [[commitController arrangedObjects] objectAtIndex:row];
	
	int a = [[NSAlert alertWithMessageText:@"Change branch"
							 defaultButton:@"Change"
						   alternateButton:@"Cancel"
							   otherButton:nil
				 informativeTextWithFormat:@"Do you want to change branch\n\n\t'%@'\n\n to point to commit\n\n\t'%@'", [ref shortName], [dropCommit subject]] runModal];
	if (a != NSAlertDefaultReturn)
		return NO;
	
	int retValue = 1;
	[historyController.repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-mUpdate from GitX", [ref ref], [dropCommit realSha], NULL] retValue:&retValue];
	if (retValue)
		return NO;
	
	[dropCommit addRef:ref];
	[oldCommit removeRef:ref];
	
	[commitController rearrangeObjects];
	[aTableView needsToDrawRect:[aTableView rectOfRow:oldRow]];
	return YES;
}

# pragma mark Branches menu

- (void) updateBranchMenu
{
	if (!branchPopUp)
		return;

	NSMutableArray *localBranches = [NSMutableArray array];
	NSMutableArray *remoteBranches = [NSMutableArray array];
	NSMutableArray *tags = [NSMutableArray array];
	NSMutableArray *other = [NSMutableArray array];

	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Branch menu"];
	for (PBGitRevSpecifier *rev in historyController.repository.branches)
	{
		if (![rev isSimpleRef])
		{
			[other addObject:rev];
			continue;
		}

		NSString *ref = [rev simpleRef];

		if ([ref hasPrefix:@"refs/heads"])
			[localBranches addObject:rev];
		else if ([ref hasPrefix:@"refs/tags"])
			[tags addObject:rev];
		else if ([ref hasPrefix:@"refs/remote"])
			[remoteBranches addObject:rev];
	}

	for (PBGitRevSpecifier *rev in localBranches)
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[rev description] action:@selector(changeBranch:) keyEquivalent:@""];
		[item setRepresentedObject:rev];
		[item setTarget:self];
		[menu addItem:item];
	}

	[menu addItem:[NSMenuItem separatorItem]];

	// Remotes
	NSMenu *remoteMenu = [[NSMenu alloc] initWithTitle:@"Remotes"];
	NSMenu *currentMenu = NULL;
	for (PBGitRevSpecifier *rev in remoteBranches)
	{
		NSString *ref = [rev simpleRef];
		NSArray *components = [ref componentsSeparatedByString:@"/"];
		
		NSString *remoteName = [components objectAtIndex:2];
		NSString *branchName = [[components subarrayWithRange:NSMakeRange(3, [components count] - 3)] componentsJoinedByString:@"/"];

		if (![[currentMenu title] isEqualToString:remoteName])
		{
			currentMenu = [[NSMenu alloc] initWithTitle:remoteName];
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:remoteName action:NULL keyEquivalent:@""];
			[item setSubmenu:currentMenu];
			[remoteMenu addItem:item];
		}

		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:branchName action:@selector(changeBranch:) keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:rev];
		[currentMenu addItem:item];
	}

	NSMenuItem *remoteItem = [[NSMenuItem alloc] initWithTitle:@"Remotes" action:NULL keyEquivalent:@""];
	[remoteItem setSubmenu:remoteMenu];
	[menu addItem:remoteItem];

	// Tags
	NSMenu *tagMenu = [[NSMenu alloc] initWithTitle:@"Tags"];
	for (PBGitRevSpecifier *rev in tags)
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[rev description] action:@selector(changeBranch:) keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:rev];
		[tagMenu addItem:item];
	}		
	
	NSMenuItem *tagItem = [[NSMenuItem alloc] initWithTitle:@"Tags" action:NULL keyEquivalent:@""];
	[tagItem setSubmenu:tagMenu];
	[menu addItem:tagItem];


	// Others
	[menu addItem:[NSMenuItem separatorItem]];

	for (PBGitRevSpecifier *rev in other)
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[rev description] action:@selector(changeBranch:) keyEquivalent:@""];
		[item setRepresentedObject:rev];
		[item setTarget:self];
		[menu addItem:item];
	}
	
	[[branchPopUp cell] setMenu: menu];
}

- (void) changeBranch:(NSMenuItem *)sender
{
	PBGitRevSpecifier *rev = [sender representedObject];
	historyController.repository.currentBranch = rev;
}

- (void) selectCurrentBranch
{
	PBGitRevSpecifier *rev = historyController.repository.currentBranch;
	if (rev)
		[branchPopUp setTitle:[rev description]];
}

@end
