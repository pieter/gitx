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
#import "PBGitDefaults.h"
#import "PBDiffWindowController.h"
#import "PBGitRevSpecifier.h"
#import "PBGitStash.h"
#import "GitXCommitCopier.h"




@implementation PBRefController

- (void)awakeFromNib
{
	[commitList registerForDraggedTypes:[NSArray arrayWithObject:@"PBGitRef"]];
}

#pragma mark Fetch

- (void) fetchRemote:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = sender.refishs.firstObject;
	if ([refish refishType] == kGitXCommitType)
		return;

	NSError *error = nil;
	BOOL success = [historyController.repository beginFetchFromRemoteForRef:refish error:&error windowController:historyController.windowController];
	if (!success) {
		[historyController.windowController showErrorSheet:error];
	}
}


#pragma mark Pull

- (void) pullRemote:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = sender.refishs.firstObject;

	NSError *error = nil;
	BOOL success = [historyController.repository beginPullFromRemote:nil forRef:refish rebase:NO error:&error windowController:historyController.windowController];
	if (!success) {
		[historyController.windowController showErrorSheet:error];
	}
}


#pragma mark Push

- (void)showConfirmPushRefSheet:(PBGitRef *)ref remote:(PBGitRef *)remoteRef
{
	if ((!ref && !remoteRef)
		|| (ref && ![ref isBranch] && ![ref isRemoteBranch] && ![ref isTag])
		|| (remoteRef && !([remoteRef refishType] == kGitXRemoteType)))
		return;

	if ([PBGitDefaults isDialogWarningSuppressedForDialog:kDialogConfirmPush]) {
		NSError *error = nil;
		BOOL success = [historyController.repository beginPushRef:ref toRemote:remoteRef error:&error windowController:historyController.windowController];
		if (!success) {
			[historyController.windowController showErrorSheet:error];
		}
		return;
	}

	NSString *description = nil;
	if (ref && remoteRef)
		description = [NSString stringWithFormat:@"Push %@ '%@' to remote %@", [ref refishType], [ref shortName], [remoteRef remoteName]];
	else if (ref)
		description = [NSString stringWithFormat:@"Push %@ '%@' to default remote", [ref refishType], [ref shortName]];
	else
		description = [NSString stringWithFormat:@"Push updates to remote %@", [remoteRef remoteName]];

    NSString * sdesc = [NSString stringWithFormat:@"p%@", [description substringFromIndex:1]]; 
	NSAlert *alert = [NSAlert alertWithMessageText:description
									 defaultButton:@"Push"
								   alternateButton:@"Cancel"
									   otherButton:nil
						 informativeTextWithFormat:@"Are you sure you want to %@?", sdesc];
    [alert setShowsSuppressionButton:YES];

	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	if (ref)
		[info setObject:ref forKey:kGitXBranchType];
	if (remoteRef)
		[info setObject:remoteRef forKey:kGitXRemoteType];

	[alert beginSheetModalForWindow:[historyController.windowController window]
					  modalDelegate:self
					 didEndSelector:@selector(confirmPushRefSheetDidEnd:returnCode:contextInfo:)
						contextInfo:(__bridge_retained void*)info];
}

- (void)confirmPushRefSheetDidEnd:(NSAlert *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [[sheet window] orderOut:nil];

	if ([[sheet suppressionButton] state] == NSOnState)
        [PBGitDefaults suppressDialogWarningForDialog:kDialogConfirmPush];

	if (returnCode == NSAlertDefaultReturn) {
		PBGitRef *ref = [(__bridge NSDictionary *)contextInfo objectForKey:kGitXBranchType];
		PBGitRef *remoteRef = [(__bridge NSDictionary *)contextInfo objectForKey:kGitXRemoteType];

		NSError *error = nil;
		BOOL success = [historyController.repository beginPushRef:ref toRemote:remoteRef error:&error windowController:historyController.windowController];
		if (!success) {
			[historyController.windowController showErrorSheet:error];
		}
	}
}

- (void) pushUpdatesToRemote:(PBRefMenuItem *)sender
{
	PBGitRef *remoteRef = [(PBGitRef *)sender.refishs.firstObject remoteRef];
	[self showConfirmPushRefSheet:nil remote:remoteRef];
}

- (void) pushDefaultRemoteForRef:(PBRefMenuItem *)sender
{
	PBGitRef *ref = sender.refishs.firstObject;
	[self showConfirmPushRefSheet:ref remote:nil];
}

- (void) pushToRemote:(PBRefMenuItem *)sender
{
	PBGitRef *ref = sender.refishs.firstObject;;
	NSString *remoteName = [sender representedObject];
	PBGitRef *remoteRef = [PBGitRef refFromString:[kGitXRemoteRefPrefix stringByAppendingString:remoteName]];

	[self showConfirmPushRefSheet:ref remote:remoteRef];
}


#pragma mark Merge

- (void) merge:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = sender.refishs.firstObject;
	NSError *error = nil;
	BOOL success = [historyController.repository mergeWithRefish:refish error:&error];
	if (!success) {
		[historyController.windowController showErrorSheet:error];
	}
}


#pragma mark Checkout

- (void) checkout:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = sender.refishs.firstObject;
	NSError *error = nil;
	BOOL success = [historyController.repository checkoutRefish:refish error:&error];
	if (!success) {
		[historyController.windowController showErrorSheet:error];
	}
}


#pragma mark Cherry Pick

- (void) cherryPick:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = sender.refishs.firstObject;
	NSError *error = nil;
	BOOL success = [historyController.repository cherryPickRefish:refish error:&error];
	if (!success) {
		[historyController.windowController showErrorSheet:error];
	}
}


#pragma mark Rebase

- (void) rebaseHeadBranch:(PBRefMenuItem *)sender
{
	id <PBGitRefish> refish = sender.refishs.firstObject;
	NSError *error = nil;
	BOOL success = [historyController.repository rebaseBranch:nil onRefish:refish error:&error];
	if (!success) {
		[historyController.windowController showErrorSheet:error];
	}
}

#pragma mark Copy info

- (void) copySHA:(PBRefMenuItem *)sender
{
	[GitXCommitCopier putStringToPasteboard:[GitXCommitCopier toFullSHA:[self commitsForMenuItem:sender]]];
}

- (void) copyShortSHA:(PBRefMenuItem *)sender
{
	[GitXCommitCopier putStringToPasteboard:[GitXCommitCopier toShortName:[self commitsForMenuItem:sender]]];
}

- (void) copyPatch:(PBRefMenuItem *)sender
{
	[GitXCommitCopier putStringToPasteboard:[GitXCommitCopier toPatch:[self commitsForMenuItem:sender]]];
}

- (NSArray<PBGitCommit *> *) commitsForMenuItem:(PBRefMenuItem *)menuItem {
	NSArray<id<PBGitRefish>> * refishs = menuItem.refishs;
	NSMutableArray *commits = [NSMutableArray arrayWithCapacity:refishs.count];
	for (id<PBGitRefish> refish in refishs) {
		[commits addObject:[self refishToCommit:refish]];
	}
	return commits;
}

- (PBGitCommit *) refishToCommit:(id<PBGitRefish>)refish {
	return [refish refishType] == kGitXCommitType
		? (PBGitCommit *)refish
		: [historyController.repository commitForRef:refish];
}


#pragma mark Diff

- (void) diffWithHEAD:(PBRefMenuItem *)sender
{
	PBGitCommit *commit = [self commitsForMenuItem:sender].firstObject;
	NSString *diff = [historyController.repository performDiff:commit against:nil forFiles:nil];

	[PBDiffWindowController showDiff:diff];
}

#pragma mark Stash

- (IBAction) stashPop:(PBRefMenuItem *)sender
{
    PBGitStash *stash = [historyController.repository stashForRef:[sender refishs].firstObject];
	NSError *error = nil;
	BOOL success = [historyController.repository stashPop:stash error:&error];

	if (!success) {
		[historyController.windowController showErrorSheet:error];
	} else {
        [historyController.windowController showCommitView:sender];
    }
}

- (IBAction) stashApply:(PBRefMenuItem *)sender
{
	PBGitStash *stash = [historyController.repository stashForRef:[sender refishs].firstObject];
	NSError *error = nil;
	BOOL success = [historyController.repository stashApply:stash error:&error];

	if (!success) {
		[historyController.windowController showErrorSheet:error];
	} else {
		[historyController.windowController showCommitView:sender];
	}
}

- (IBAction) stashDrop:(PBRefMenuItem *)sender
{
	PBGitStash * stash = [historyController.repository stashForRef:[sender refishs].firstObject];
	NSError *error = nil;
	BOOL success = [historyController.repository stashDrop:stash error:&error];

	if (!success) {
		[historyController.windowController showErrorSheet:error];
	} else {
		[historyController.windowController showHistoryView:sender];
	}
}

- (IBAction) stashViewDiff:(PBRefMenuItem *)sender
{
    PBGitStash * stash = [historyController.repository stashForRef:sender.refishs.firstObject];
    [PBDiffWindowController showDiffWindowWithFiles:nil fromCommit:stash.ancestorCommit diffCommit:stash.commit];
}

#pragma mark Tags

- (void) showTagInfoSheet:(PBRefMenuItem *)sender
{
	id<PBGitRefish> refish = sender.refishs.firstObject;
	if ([refish refishType] != kGitXTagType)
		return;

	PBGitRef *ref = (PBGitRef *)refish;

	NSString *tagName = [ref tagName];
	NSString *tagRef = [@"refs/tags/" stringByAppendingString:tagName];
	NSError *error = nil;
	GTObject *object = [historyController.repository.gtRepo lookUpObjectByRevParse:tagRef error:&error];
	if (!object) {
		NSLog(@"Couldn't look up ref %@:%@", tagRef, [error debugDescription]);
		return;
	}
	NSString* title = [NSString stringWithFormat:@"Info for tag: %@", tagName];
	NSString* info = @"";
	if ([object isKindOfClass:[GTTag class]]) {
		GTTag *tag = (GTTag*)object;
		info = tag.message;
	}
	[historyController.windowController showMessageSheet:title infoText:info];
}


#pragma mark Remove a branch, remote or tag

- (IBAction)showDeleteRefSheet:(PBRefMenuItem *)sender
{
	id<PBGitRefish> refish = sender.refishs.firstObject;
	if ([refish refishType] == kGitXCommitType)
		return;

	PBGitRef *ref = (PBGitRef *)refish;

	if ([PBGitDefaults isDialogWarningSuppressedForDialog:kDialogDeleteRef]) {
		NSError *error = nil;
		BOOL success = [historyController.repository deleteRef:ref error:&error];
		if (!success) {
			[historyController.windowController showErrorSheet:error];
		}
		return;
	}

	NSString *ref_desc = [NSString stringWithFormat:@"%@ '%@'", [ref refishType], [ref shortName]];

	NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Delete %@?", ref_desc]
									 defaultButton:@"Delete"
								   alternateButton:@"Cancel"
									   otherButton:nil
						 informativeTextWithFormat:@"Are you sure you want to remove the %@?", ref_desc];
    [alert setShowsSuppressionButton:YES];
	
	[alert beginSheetModalForWindow:[historyController.windowController window]
					  modalDelegate:self
					 didEndSelector:@selector(deleteRefSheetDidEnd:returnCode:contextInfo:)
						contextInfo:(__bridge_retained void*)ref];
}

- (void)deleteRefSheetDidEnd:(NSAlert *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    [[sheet window] orderOut:nil];

	if ([[sheet suppressionButton] state] == NSOnState)
        [PBGitDefaults suppressDialogWarningForDialog:kDialogDeleteRef];

	if (returnCode == NSAlertDefaultReturn) {
		PBGitRef *ref = (__bridge PBGitRef *)contextInfo;

		NSError *error = nil;
		BOOL success = [historyController.repository deleteRef:ref error:&error];
		if (!success) {
			[historyController.windowController showErrorSheet:error];
		}
	}
}



#pragma mark Contextual menus

- (NSArray<NSMenuItem *> *) menuItemsForRef:(PBGitRef *)ref
{
	return [PBRefMenuItem defaultMenuItemsForRef:ref inRepository:historyController.repository target:self];
}

- (NSArray<NSMenuItem *> *) menuItemsForCommits:(NSArray<PBGitCommit *> *)commits
{
	return [PBRefMenuItem defaultMenuItemsForCommits:commits target:self];
}

- (NSArray<NSMenuItem *> *)menuItemsForRow:(NSInteger)rowIndex
{
	NSArray<PBGitCommit *> *commits = [commitController arrangedObjects];
	if ([commits count] <= rowIndex)
		return nil;

	return [self menuItemsForCommits:@[[commits objectAtIndex:rowIndex]]];
}



# pragma mark Tableview delegate methods

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    
	NSPoint location = [(PBCommitList *)tv mouseDownPoint];
	NSInteger row = [tv rowAtPoint:location];
	NSInteger column = [tv columnAtPoint:location];
	
	PBGitRevisionCell *cell = (PBGitRevisionCell *)[tv preparedCellAtColumn:column row:row];
	PBGitCommit *commit = [[commitController arrangedObjects] objectAtIndex:row];

	int index = -1;
	if ([cell respondsToSelector:@selector(indexAtX:)]) {
		NSRect cellFrame = [tv frameOfCellAtColumn:column row:row];
		CGFloat deltaX = location.x - cellFrame.origin.x;
		index = [cell indexAtX:deltaX];
	}
	
	if (index != -1) {
		PBGitRef *ref = [[commit refs] objectAtIndex:index];
		if ([ref isTag] || [ref isRemoteBranch])
			return NO;

		if ([[[historyController.repository headRef] ref] isEqualToRef:ref])
			return NO;

		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:[NSNumber numberWithInteger:row], [NSNumber numberWithInt:index], NULL]];
		[pboard declareTypes:[NSArray arrayWithObject:@"PBGitRef"] owner:self];
		[pboard setData:data forType:@"PBGitRef"];
	} else {
		[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];

		NSString *info = nil;
		if (column == [tv columnWithIdentifier:@"ShortSHAColumn"]) {
			info = [commit shortName];
		} else {
			info = [NSString stringWithFormat:@"%@ (%@)", [commit shortName], [commit subject]];
		}

		[pboard setString:info forType:NSStringPboardType];
	}

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

- (void) dropRef:(NSDictionary *)dropInfo
{
	PBGitRef *ref = [dropInfo objectForKey:@"dragRef"];
	PBGitCommit *oldCommit = [dropInfo objectForKey:@"oldCommit"];
	PBGitCommit *dropCommit = [dropInfo objectForKey:@"dropCommit"];
	if (!ref || ! oldCommit || !dropCommit)
		return;

	if (![historyController.repository updateReference:ref toPointAtCommit:dropCommit])

	[dropCommit addRef:ref];
	[oldCommit removeRef:ref];
	[historyController.commitList reloadData];
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
	if (oldRow == row)
		return NO;

	int oldRefIndex = [[numbers objectAtIndex:1] intValue];
	PBGitCommit *oldCommit = [[commitController arrangedObjects] objectAtIndex:oldRow];
	PBGitRef *ref = [[oldCommit refs] objectAtIndex:oldRefIndex];

	PBGitCommit *dropCommit = [[commitController arrangedObjects] objectAtIndex:row];

	NSDictionary *dropInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  ref, @"dragRef",
							  oldCommit, @"oldCommit",
							  dropCommit, @"dropCommit",
							  nil];

	if ([PBGitDefaults isDialogWarningSuppressedForDialog:kDialogAcceptDroppedRef]) {
		[self dropRef:dropInfo];
		return YES;
	}

	NSString *subject = [dropCommit subject];
	if ([subject length] > 99)
		subject = [[subject substringToIndex:99] stringByAppendingString:@"…"];
	NSString *infoText = [NSString stringWithFormat:@"Move the %@ to point to the commit: %@", [ref refishType], subject];

	NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Move %@: %@", [ref refishType], [ref shortName]]
									 defaultButton:@"Move"
								   alternateButton:@"Cancel"
									   otherButton:nil
						 informativeTextWithFormat:@"%@", infoText];
    [alert setShowsSuppressionButton:YES];

	[alert beginSheetModalForWindow:[historyController.windowController window]
					  modalDelegate:self
					 didEndSelector:@selector(acceptDropInfoAlertDidEnd:returnCode:contextInfo:)
						contextInfo:(__bridge_retained void*)dropInfo];

	return YES;
}

- (void)acceptDropInfoAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [[alert window] orderOut:nil];

	if (returnCode == NSAlertDefaultReturn)
		[self dropRef:(__bridge NSDictionary*)contextInfo];

	if ([[alert suppressionButton] state] == NSOnState)
        [PBGitDefaults suppressDialogWarningForDialog:kDialogAcceptDroppedRef];
}

- (void)dealloc {
    historyController = nil;
}

@end
