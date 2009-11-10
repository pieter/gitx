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
#import "KBPopUpToolbarItem.h"

@implementation PBRefController

- (void)awakeFromNib
{
	[commitList registerForDraggedTypes:[NSArray arrayWithObject:@"PBGitRef"]];
	[historyController addObserver:self forKeyPath:@"repository.branches" options:0 context:@"branchChange"];
	[historyController addObserver:self forKeyPath:@"repository.currentBranch" options:0 context:@"currentBranchChange"];
	[self updateBranchMenus];
	[self selectCurrentBranch];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(NSString *)context isEqualToString: @"branchChange"]) {
		[self updateBranchMenus];
	}
	else if ([(NSString *)context isEqualToString:@"currentBranchChange"]) {
		[self selectCurrentBranch];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) removeRefSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		int ret = 1;
        PBRefMenuItem *refMenuItem = contextInfo;
		[historyController.repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-d", [[refMenuItem ref] ref], nil] retValue: &ret];
		if (ret) {
			NSLog(@"Removing ref failed!");
			return;
		}
		[historyController.repository removeBranch:[[PBGitRevSpecifier alloc] initWithRef:[refMenuItem ref]]];
		[[refMenuItem commit] removeRef:[refMenuItem ref]];
		[commitController rearrangeObjects];
        [self updateBranchMenus];
	}
}

- (void) removeRef:(PBRefMenuItem *)sender
{
	NSString *ref_desc = [NSString stringWithFormat:@"%@ %@", [[sender ref] type], [[sender ref] shortName]];
	NSString *question = [NSString stringWithFormat:@"Are you sure you want to remove the %@?", ref_desc];
    NSBeginAlertSheet([NSString stringWithFormat:@"Delete %@?", ref_desc], @"Delete", @"Cancel", nil, [[historyController view] window], self, @selector(removeRefSheetDidEnd:returnCode:contextInfo:), NULL, sender, question);
}

- (void) checkoutRef:(PBRefMenuItem *)sender
{
	int ret = 1;
	[historyController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"checkout", [[sender ref] shortName], nil] retValue: &ret];
	if (ret) {
		NSString *info = [NSString stringWithFormat:@"There was an error checking out the branch. Perhaps your working directory is not clean?"];
		[[historyController.repository windowController] showMessageSheet:@"Checking out branch failed" infoText:info];
		return;
	}
	[historyController.repository reloadRefs];
	[historyController.repository readCurrentBranch];
	[commitController rearrangeObjects];
}

- (void) pushRef:(PBRefMenuItem *)sender
{
	[self pushImpl:[[sender ref] shortName]];
}

- (void) pullRef:(PBRefMenuItem *)sender
{
	[self pullImpl:[[sender ref] shortName]];
}

- (void) rebaseRef:(PBRefMenuItem *)sender
{
	[self rebaseImpl:[[sender ref] shortName]];
}

- (BOOL) fetchRef:(PBRefMenuItem *)sender
{
	[self fetchImpl:[[sender ref] shortName]];
}

- (BOOL) pushRef:(NSString *)refName toRemote:(NSString *)remote
{
	int ret = 1;
    BOOL success = NO;
	NSString *rval = [historyController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"push", remote, refName, nil] retValue: &ret];
    if (!remote) {
        [self showMessageSheet:@"Push to Remote" message:PBMissingRemoteErrorMessage];
        return success;
    }
	if (ret) {
		NSString *info = [NSString stringWithFormat:@"There was an error pushing the branch to the remote repository.\n\n%d\n%@", ret, rval];
		[[historyController.repository windowController] showMessageSheet:@"Pushing branch failed" infoText:info];
		return success;
	}
	[historyController.repository reloadRefs];
	[commitController rearrangeObjects];
    success = YES;
    return success;
}

- (BOOL) pullRef:(NSString *)refName fromRemote:(NSString *)remote
{
	int ret = 1;
    BOOL success = NO;
    NSArray * args = [NSArray arrayWithObjects:@"pull", remote, refName, nil];    
	NSString *rval = [historyController.repository outputInWorkdirForArguments:args retValue: &ret];
	if (ret) {
		NSString *info = [NSString stringWithFormat:@"There was an error pulling from the remote repository.\n\n%d\n%@", ret, rval];
		[[historyController.repository windowController] showMessageSheet:@"Pulling from remote failed" infoText:info];
		return success;
	}
	[historyController.repository reloadRefs];
	[commitController rearrangeObjects];
    success = YES;
    return success;
}

- (BOOL) rebaseRef:(NSString *)refName fromRemote:(NSString *)remote
{
	int ret = 1;
    BOOL success = NO;
    NSArray * args = [NSArray arrayWithObjects:@"pull", @"--rebase", remote, refName, nil];    
	NSString *rval = [historyController.repository outputInWorkdirForArguments:args retValue: &ret];
	if (ret) {
		NSString *info = [NSString stringWithFormat:@"There was an error pulling from the remote repository.\n\n%d\n%@", ret, rval];
		[[historyController.repository windowController] showMessageSheet:@"Pulling from remote failed" infoText:info];
		return success;
	}
	[historyController.repository reloadRefs];
	[commitController rearrangeObjects];
    success = YES;
    return success;
}

- (BOOL) fetchRef:(NSString *)refName fromRemote:(NSString *)remote
{
	int ret = 1;
    BOOL success = NO;
    NSArray * args = [NSArray arrayWithObjects:@"pull", @"--rebase", remote, refName, nil];    
	NSString *rval = [historyController.repository outputInWorkdirForArguments:args retValue: &ret];
	if (ret) {
		NSString *info = [NSString stringWithFormat:@"There was an error pulling from the remote repository.\n\n%d\n%@", ret, rval];
		[[historyController.repository windowController] showMessageSheet:@"Pulling from remote failed" infoText:info];
		return success;
	}
	[historyController.repository reloadRefs];
	[commitController rearrangeObjects];
    success = YES;
    return success;
}

- (BOOL) pushImpl:(NSString *)refName
{
	NSString *remote = [[historyController.repository config] valueForKeyPath:[NSString stringWithFormat:@"branch.%@.remote", refName]];
    if (!remote) {
        [self showMessageSheet:@"Push to Remote" message:PBMissingRemoteErrorMessage];
        return NO;
    }
    return [self pushRef:refName toRemote:remote];
}

- (BOOL) pullImpl:(NSString *)refName
{
	NSString *remote = [[historyController.repository config] valueForKeyPath:[NSString stringWithFormat:@"branch.%@.remote", refName]];
    if (!remote) {
        [self showMessageSheet:@"Pull from Remote" message:PBMissingRemoteErrorMessage];
        return NO;
    }
    return [self pullRef:refName fromRemote:remote];
}

- (BOOL) rebaseImpl:(NSString *)refName
{
	NSString *remote = [[[historyController repository] config] valueForKeyPath:[NSString stringWithFormat:@"branch.%@.remote", refName]];
    if (!remote) {
        [self showMessageSheet:@"Pull from Remote and Rebase" message:PBMissingRemoteErrorMessage];
        return NO;
    }
    return [self rebaseRef:refName fromRemote:remote];
}

- (BOOL) fetchImpl:(NSString *)refName
{
	NSString *remote = [[historyController.repository config] valueForKeyPath:[NSString stringWithFormat:@"branch.%@.remote", refName]];
    if (!remote) {
        [self showMessageSheet:@"Fetch from Remote" message:PBMissingRemoteErrorMessage];
        return NO;
    }
    return [self fetchRef:refName fromRemote:remote];
}

- (void) tagInfo:(PBRefMenuItem *)sender
{
    NSString *message = [NSString stringWithFormat:@"Info for tag: %@", [[sender ref] shortName]];
    
    int ret = 1;
    NSString *info = [historyController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"tag", @"-n50", @"-l", [[sender ref] shortName], nil] retValue: &ret];
    
    if (!ret) {
	    [[historyController.repository windowController] showMessageSheet:message infoText:info];
    }
    return;
}

- (NSArray *) menuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit
{
	return [PBRefMenuItem defaultMenuItemsForRef:ref commit:commit target:self];
}

- (BOOL) addRemoteImplWithName:(NSString *)remoteName forURL:(NSString *)remoteURL
{
	int ret = 1;
    BOOL success = NO;
    if (!remoteName || !remoteURL) {
        return success;
    }
	NSString *rval = [historyController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"remote",  @"add", @"-f", remoteName, remoteURL, nil] retValue: &ret];
	if (ret) {
		NSString *info = [NSString stringWithFormat:@"There was an error adding the remote.\n\n%d\n%@", ret, rval];
		[[historyController.repository windowController] showMessageSheet:@"Adding Remote failed" infoText:info];
		return success;
	}
	[historyController.repository reloadRefs];
	[commitController rearrangeObjects];
    success = YES;
    return success;
}

- (void) toggleToolbarItems:(NSToolbar *)tb matchingLabels:(NSArray *)labels enabledState:(BOOL)state  {
    NSArray * tbItems = [tb items];
    
    /* if labels is nil, assume all toolbar items */
    if (!labels) {
        for (NSToolbarItem * curItem in tbItems) {
            [curItem setEnabled:state];
        }
    } else {
        for (NSToolbarItem * curItem in tbItems) {
            for (NSString * curLabel in labels) {
                if ([[curItem label] isEqualToString:curLabel]) {
                    [curItem setEnabled:state];
                }
            }
        }
    }
}

# pragma mark Tableview delegate methods

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSPoint location = [tv convertPointFromBase:[(PBCommitList *)tv mouseDownPoint]];
	int row = [tv rowAtPoint:location];
	int column = [tv columnAtPoint:location];
	if (column != 0)
		return NO;
	
	PBGitRevisionCell *cell = (PBGitRevisionCell *)[tv preparedCellAtColumn:column row:row];
	
	int index = [cell indexAtX:location.x];
	
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

# pragma mark Add ref methods


-(void)addRef:(id)sender
{
   [errorMessage setStringValue:@""];
  [NSApp beginSheet:newBranchSheet
      modalForWindow:[[historyController view] window]
       modalDelegate:NULL
      didEndSelector:NULL
         contextInfo:NULL];
}

// MARK: Buttons
-(void)rebaseButton:(id)sender
{
	NSString *refName = [[[[historyController repository] currentBranch] simpleRef] refForSpec];
    if (refName) {
        [self rebaseImpl:refName];
    } else {        
        [self showMessageSheet:@"Pull Rebase from Remote" message:PBInvalidBranchErrorMessage];
    }
    //	NSLog([NSString stringWithFormat:@"Rebase hit for %@!", refName]);
}

-(void)pushButton:(id)sender
{
	NSString *refName = [[[[historyController repository] currentBranch] simpleRef] refForSpec];
    if (refName) {
        [self pushImpl:refName];
    } else {
        [self showMessageSheet:@"Push to Remote" message:PBInvalidBranchErrorMessage];
    }
    //	NSLog([NSString stringWithFormat:@"Push hit for %@!", refName]);
}

- (void) pullButton:(id)sender 
{
    NSString * refName = [[[[historyController repository] currentBranch] simpleRef] refForSpec];
    if (refName) {
        [self pullImpl:refName];
    } else {
        [sender setEnabled:YES];
        [self showMessageSheet:@"Pull from Remote" message:PBInvalidBranchErrorMessage];
    }
    //	NSLog([NSString stringWithFormat:@"Pull hit for %@!", refName]);
}

-(void)fetchButton:(id)sender
{
	NSString *refName = [[[[historyController repository] currentBranch] simpleRef] refForSpec];
    if (refName) {
        [self fetchImpl:refName];
    } else {
        [sender setEnabled:YES];
        [self showMessageSheet:@"Fetch from Remote" message:PBInvalidBranchErrorMessage];
    }
    //	NSLog([NSString stringWithFormat:@"Fetch hit for %@!", refName]);
}

// MARK: Sheets

- (void) showMessageSheet:(NSString *)title message:(NSString *)msg {

    [[NSAlert alertWithMessageText:title
                     defaultButton:@"OK"
                   alternateButton:nil
                       otherButton:nil
         informativeTextWithFormat:msg] 
                 beginSheetModalForWindow:[[historyController view] window] 
                            modalDelegate:self 
                           didEndSelector:nil 
                              contextInfo:nil];
    
    return;
}

-(void)saveSheet:(id) sender
{
	NSString *branchName = [@"refs/heads/" stringByAppendingString:[newBranchName stringValue]];
	
	if ([[commitController selectedObjects] count] == 0)
		return;

	PBGitCommit *commit = [[commitController selectedObjects] objectAtIndex:0];

	int retValue = 1;
	[historyController.repository outputForArguments:[NSArray arrayWithObjects:@"check-ref-format", branchName, nil] retValue:&retValue];
	if (retValue != 0) {
		[errorMessage setStringValue:@"Invalid name"];
		return;
	}

	retValue = 1;
	[historyController.repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-mCreate branch from GitX", branchName, [commit realSha], @"0000000000000000000000000000000000000000", NULL] retValue:&retValue];
	if (retValue)
	{
		[errorMessage setStringValue:@"Branch exists"];
		return;
	}
	[historyController.repository addBranch:[[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:branchName]]];
	[self closeSheet:sender];
	[commit addRef:[PBGitRef refFromString:branchName]];
	[commitController rearrangeObjects];
}

-(void)closeSheet:(id) sender
{	
	[NSApp endSheet:newBranchSheet];
	[newBranchName setStringValue:@""];
	[newBranchSheet orderOut:self];
}

- (void) addRemoteButton:(id)sender
{
    [addRemoteErrorMessage setStringValue:@""];
	[addRemoteName setStringValue:@""];
    [addRemoteName setTextColor:[NSColor blackColor]];
	[addRemoteURL setStringValue:@""];
    [NSApp beginSheet:addRemoteSheet
       modalForWindow:[[historyController view] window]
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];
}

- (void) addRemoteSheet:(id)sender
{
    NSString *remoteName = [addRemoteName stringValue];
    NSString *remoteURL = [addRemoteURL stringValue];
    NSLog(@"%s  remoteName = %@  remoteURL = %@", _cmd, remoteName, remoteURL);
    
    if ([remoteName isEqualToString:@""]) {
        [addRemoteErrorMessage setStringValue:@"Remote name is required"];
        return;
    }
    
    NSRange range = [remoteName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (range.location != NSNotFound) {
        [addRemoteErrorMessage setStringValue:@"Whitespace is not allowed"];
        [addRemoteName setTextColor:[NSColor redColor]];
        return;
    }
    
    [addRemoteName setTextColor:[NSColor blackColor]];
    
    if ([remoteURL isEqualToString:@""]) {
        [addRemoteErrorMessage setStringValue:@"Remote URL is required"];
        return;
    }
    
    [addRemoteURL setTextColor:[NSColor blackColor]];
    
    [self closeAddRemoteSheet:sender];
    
    [self addRemoteImplWithName:remoteName forURL:remoteURL];
}

- (void) closeAddRemoteSheet:(id)sender
{	
	[NSApp endSheet:addRemoteSheet];
    [addRemoteErrorMessage setStringValue:@""];
	[addRemoteName setStringValue:@""];
    [addRemoteName setTextColor:[NSColor blackColor]];
	[addRemoteURL setStringValue:@""];
	[addRemoteSheet orderOut:self];
}

- (void) newTagButton:(id)sender
{
    [newTagErrorMessage setStringValue:@""];
	[newTagName setStringValue:@""];
    
	if ([[commitController selectedObjects] count] != 0) {
		PBGitCommit *commit = [[commitController selectedObjects] objectAtIndex:0];
        [newTagCommit setStringValue:[commit subject]];
        [newTagSHA	setStringValue:[commit realSha]];
        [newTagSHALabel setHidden:NO];
    } else {
        [newTagCommit setStringValue:historyController.repository.currentBranch.description];
        [newTagSHA	setStringValue:@""];
        [newTagSHALabel setHidden:YES];
    }

    
    [NSApp beginSheet:newTagSheet
       modalForWindow:[[historyController view] window]
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];
}

- (void) newTagSheet:(id)sender
{
    NSString *tagName = [newTagName stringValue];

    if ([tagName isEqualToString:@""]) {
		[newTagErrorMessage setStringValue:@"Invalid name"];
		return;
	}

    PBGitCommit *commit = nil;
	if ([[commitController selectedObjects] count] != 0)
		commit = [[commitController selectedObjects] objectAtIndex:0];
    
	NSString *refName = [@"refs/tags/" stringByAppendingString:tagName];
	int retValue = 1;
	[historyController.repository outputForArguments:[NSArray arrayWithObjects:@"check-ref-format", refName, nil] retValue:&retValue];
	if (retValue != 0) {
		[newTagErrorMessage setStringValue:@"Invalid name"];
		return;
	}

	NSString *message = [newTagMessage string];
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"tag"];
    if (![message isEqualToString:@""]) {
        [arguments addObject:[@"-m" stringByAppendingString:message]];
    }
    [arguments addObject:tagName];
    if (commit) {
        [arguments addObject:[commit realSha]];
    }
    NSLog(@"arguments = %@", arguments);
	retValue = 1;
	[historyController.repository outputForArguments:arguments retValue:&retValue];
	if (retValue)
	{
		[newTagErrorMessage setStringValue:@"Tag exists"];
		return;
	}
    
    [self closeNewTagSheet:sender];
	[historyController.repository reloadRefs];
	[commitController rearrangeObjects];
}

- (void) closeNewTagSheet:(id)sender
{	
	[NSApp endSheet:newTagSheet];
    [newTagErrorMessage setStringValue:@""];
	[newTagName setStringValue:@""];
	[newTagSheet orderOut:self];
}

# pragma mark Branch menus

- (void) updateAllBranchesMenuWithLocal:(NSMutableArray *)localBranches remote:(NSMutableArray *)remoteBranches tag:(NSMutableArray *)tags other:(NSMutableArray *)other
{
	if (!branchPopUp)
        return;

	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Branch menu"];

    // Local
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
	NSMenu *currentMenu = nil;
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

- (void) updatePopUpToolbarItemMenu:(KBPopUpToolbarItem *)item remotes:(NSMutableArray *)remoteBranches action:(SEL)action title:(NSString *)menuTitle
{
    if (!item)
        return;
    
	NSMenu *remoteMenu = [[NSMenu alloc] initWithTitle:menuTitle];
    
    // Remotes
	NSMenu *currentMenu = nil;
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
        
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:branchName action:action keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:rev];
		[currentMenu addItem:item];
	}
    
    [item setMenu: remoteMenu];
}

// !!! Andre Berg 20091110: The two methods below have been replaced with a more generic one (see above).
// Need to remove this at a later time...

/*
- (void) updatePullMenuWithRemotes:(NSMutableArray *)remoteBranches
{
    if (!pullItem)
        return;

	NSMenu *remoteMenu = [[NSMenu alloc] initWithTitle:@"Pull menu"];

    // Remotes
	NSMenu *currentMenu = nil;
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

		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:branchName action:@selector(pullMenuAction:) keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:rev];
		[currentMenu addItem:item];
	}

    [pullItem setMenu: remoteMenu];
}

- (void) updatePushMenuWithRemotes:(NSMutableArray *)remoteBranches
{
    if (!pushItem)
        return;

	NSMenu *remoteMenu = [[NSMenu alloc] initWithTitle:@"Push menu"];

    // Remotes
	NSMenu *currentMenu = nil;
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

		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:branchName action:@selector(pushMenuAction:) keyEquivalent:@""];
		[item setTarget:self];
		[item setRepresentedObject:rev];
		[currentMenu addItem:item];
	}

    [pushItem setMenu: remoteMenu];
}*/

- (void) updateBranchMenus
{
	NSMutableArray *localBranches = [NSMutableArray array];
	NSMutableArray *remoteBranches = [NSMutableArray array];
	NSMutableArray *tags = [NSMutableArray array];
	NSMutableArray *other = [NSMutableArray array];

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

    [self updateAllBranchesMenuWithLocal:localBranches remote:remoteBranches tag:tags other:other];
    
    [self updatePopUpToolbarItemMenu:pushItem remotes:remoteBranches action:@selector(pushMenuAction:) title:@"Push menu"];
    [self updatePopUpToolbarItemMenu:pullItem remotes:remoteBranches action:@selector(pullMenuAction:) title:@"Push menu"];
    [self updatePopUpToolbarItemMenu:rebaseItem remotes:remoteBranches action:@selector(rebaseMenuAction:) title:@"Push menu"];

// 	[self updatePullMenuWithRemotes:remoteBranches];
// 
// 	[self updatePushMenuWithRemotes:remoteBranches];
}

- (void) changeBranch:(NSMenuItem *)sender
{
	PBGitRevSpecifier *rev = [sender representedObject];
	historyController.repository.currentBranch = rev;
}

- (void) selectCurrentBranch
{
	PBGitRevSpecifier *rev = historyController.repository.currentBranch;
    [branchPopUp setTitle:[rev description]];

    // !!! Andre Berg 20091110: I don't think this is needed any more since the Push, Pull 
    // and Rebase toolbar items are now popup buttons it makes no sense to disable them 
    // when switching to "All branches" or "Local branches" since you can choose the remote
    // from the popup menus.

    //     NSToolbar * tb = historyController.viewToolbar;
    //     NSArray * tbLabels = [NSArray arrayWithObjects:@"Push", @"Pull", @"Rebase", nil];
    // 	if (rev) {
    //         [branchPopUp setTitle:[rev description]];
    //         
    //         if ([[rev description] isEqualToString:@"All branches"] ||
    //             [[rev description] isEqualToString:@"Local branches"]) 
    //         {
    //             [self toggleToolbarItems:tb matchingLabels:tbLabels enabledState:NO];
    //         } else {
    //             [self toggleToolbarItems:tb matchingLabels:tbLabels enabledState:YES];
    //         }
    //     } else {
    //         /* just in case, re-enable all toolbar buttons */
    //         [self toggleToolbarItems:tb matchingLabels:nil enabledState:YES];
    //     }
}

- (void) pullMenuAction:(NSMenuItem *)sender
{
    NSString *ref = [(PBGitRevSpecifier *)[sender representedObject] description];
    NSArray *refComponents = [ref componentsSeparatedByString:@"/"];
    if ([refComponents count] != 2)
        return;
    [self pullRef:[refComponents objectAtIndex:1] fromRemote:[refComponents objectAtIndex:0]];
}

- (void) pushMenuAction:(NSMenuItem *)sender
{
    NSString *ref = [(PBGitRevSpecifier *)[sender representedObject] description];
    NSArray *refComponents = [ref componentsSeparatedByString:@"/"];
    if ([refComponents count] != 2)
        return;
    [self pushRef:[refComponents objectAtIndex:1] toRemote:[refComponents objectAtIndex:0]];
}

- (void) rebaseMenuAction:(NSMenuItem *)sender
{
    NSString *ref = [(PBGitRevSpecifier *)[sender representedObject] description];
    NSArray *refComponents = [ref componentsSeparatedByString:@"/"];
    if ([refComponents count] != 2)
        return;
    [self rebaseRef:[refComponents objectAtIndex:1] fromRemote:[refComponents objectAtIndex:0]];
}

@end

@implementation NSString (PBRefSpecAdditions)

/* convenience method to get the last part of a simple refspec like refs/heads/master -> master*/
- (NSString *) refForSpec {
    if ([self hasPrefix:@"refs/"]) {
        NSArray * parts = [self componentsSeparatedByString:@"/"];
        return [parts lastObject];
    }
    return self;
}

@end

