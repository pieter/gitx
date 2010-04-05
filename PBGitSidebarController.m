//
//  PBGitSidebar.m
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PBGitSidebarController.h"
#import "PBSourceViewItems.h"
#import "PBGitHistoryController.h"
#import "PBGitCommitController.h"
#import "PBRefController.h"
#import "PBSourceViewCell.h"
#import "NSOutlineViewExt.h"
#import "PBAddRemoteSheet.h"
#import "PBGitDefaults.h"
#import "BMScript.h"
#import "ApplicationController.h"

@interface PBGitSidebarController ()

- (void)populateList;
- (void)addRevSpec:(PBGitRevSpecifier *)revSpec;
- (PBSourceViewItem *) itemForRev:(PBGitRevSpecifier *)rev;
- (void) removeRevSpec:(PBGitRevSpecifier *)rev;
- (void) updateActionMenu;

@end

@implementation PBGitSidebarController
@synthesize items;
@synthesize sourceListControlsView, sourceView, remotes;
@synthesize deferredSelectObject;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller
{
	self = [super initWithRepository:theRepository superController:controller];
	[sourceView setDelegate:self];
	items = [NSMutableArray array];
    deferredSelectObject = nil;
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	window.contentView = [self view];
	[self populateList];

	historyViewController = [[PBGitHistoryController alloc] initWithRepository:repository superController:superController];
	commitViewController = [[PBGitCommitController alloc] initWithRepository:repository superController:superController];

    superController.historyController = historyViewController;

    historyViewController.sidebarSourceView = self.sourceView;
    historyViewController.sidebarRemotes = self.remotes;

    [repository addObserver:self forKeyPath:@"currentBranch" options:0 context:@"currentBranchChange"];
	[repository addObserver:self forKeyPath:@"branches" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:@"branchesModified"];

	[self menuNeedsUpdate:[actionButton menu]];

	if ([PBGitDefaults showStageView])
		[self selectStage];
	else
        [self selectCurrentBranch];
}

- (void)populateList
{
    NSLog(@"[%@ %s]", [self class], _cmd);

	PBSourceViewItem *project = [PBSourceViewItem groupItemWithTitle:[repository projectName]];
	project.isUncollapsible = YES;

	stage = [PBGitSVStageItem stageItem];
	[project addChild:stage];

	branches = [PBSourceViewItem groupItemWithTitle:@"Branches"];
	remotes = [PBSourceViewItem groupItemWithTitle:@"Remotes"];
	tags = [PBSourceViewItem groupItemWithTitle:@"Tags"];
	others = [PBSourceViewItem groupItemWithTitle:@"Other"];

	for (PBGitRevSpecifier *branchRev in repository.branches)
		[self addRevSpec:branchRev];

    [items addObject:project];
	[items addObject:branches];
	[items addObject:remotes];
	[items addObject:tags];
	[items addObject:others];

	[sourceView reloadData];
	[sourceView expandItem:project];
	[sourceView expandItem:branches expandChildren:YES];
	[sourceView expandItem:remotes];

	[sourceView reloadItem:nil reloadChildren:YES];

    // figure out if args passed to gitx are meaningful enough to describe a source view branch
    // and a selectable commit on the history view controller...

    ApplicationController * appController = [ApplicationController sharedApplicationController];
    PBGitRevSpecifier * resolvedRev = nil;

//     if (YES) {
//         //appController.cliArgs = @"rdi/master";
//         //appController.cliArgs = @"d12b92349bb89bc83b8eab45a4bed88d50547aeb";
//         appController.cliArgs = @"--commit";
//         appController.launchedFromGitx = YES;
//     }

    NSString * cliargs = appController.cliArgs;

    // if the cliArgs have a "-" prefix it might be one of the "--all", "--local", "--commit", "-S..." etc.
    // parameters (see ApplicationController.m and gitx.m) then don't set the deferredSelectObject and continue
    // as normal
    if (appController.launchedFromGitx && cliargs && !([cliargs hasPrefix:@"-"])) {

        repository.currentBranchFilter = [PBGitDefaults branchFilter];

        // is it a partial ref ? (like xyz/master) - try to complete the rev
        PBGitRef * ref;
        if (ref = [repository completeRefForString:cliargs]) {
            NSLog(@"[%@ %s] completed ref for %@ = %@", [self class], _cmd, cliargs, ref);
            if (ref) {
                resolvedRev = [[PBGitRevSpecifier alloc] initWithRef:ref];
            }
        } else {
            // is it a SHA ? - figure out the branch the SHA lives in
            if ((appController.deferredSelectSha = [repository shaExists:cliargs])) {

                NSLog(@"[%@ %s] appController.deferredSelectSha = %@", [self class], _cmd, appController.deferredSelectSha);

                // this little shell script looks up the rev for a SHA and gets the refs/... path
                // for its most recent commit (aka head commit (but not _the_ HEAD)
                NSString * headRefPathForShaTemplate = [NSString stringWithString:@"#!/bin/sh\n"
                                                                                  @"cd \"%{DIR}\"\n"
                                                                                  @"br=`%{GITPATH} name-rev \"%{SHA}\" | awk '{gsub(/~.*/,\"\",$2);print $2}'`\n"
                                                                                  @"headsha=`%{GITPATH} rev-parse $br`\n"
                                                                                  @"%{GITPATH} show-ref | grep $headsha | awk '{print $2}'\n"];

                NSDictionary * kwds = [NSDictionary dictionaryWithObjectsAndKeys:[PBGitBinary path], @"GITPATH",
                                                                      [repository workingDirectory], @"DIR",
                                                                                            cliargs, @"SHA", nil];

                TerminationStatus retVal = BMScriptNotExecuted;
                NSString * output = [repository outputForShellScriptTemplate:headRefPathForShaTemplate
                                                                 keywordDict:kwds
                                                                    retValue:&retVal];

                if (BMScriptFinishedSuccessfully == retVal) {
                    output = [output substringToIndex:[output length] - 1]; // trim \n
                    if ([output rangeOfString:@"\n"].location != NSNotFound) {
                        NSArray * lines = [output componentsSeparatedByString:@"\n"];
                        resolvedRev = [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:[lines objectAtIndex:0]]];
                    } else {
                        resolvedRev = [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:output]];
                    }
                }
            }
        }
        // now try to find resolvedRev in the sourceView and store it
        // in defereredSelectObject so we can select it later
        if (resolvedRev) {
            repository.currentBranch = resolvedRev;
            //repository.currentBranch.isSimpleRef = YES;
            NSLog(@"[%@ %s] currentBranch = %@", [self class], _cmd, repository.currentBranch);
            NSLog(@"[%@ %s] items = %@", [self class], _cmd, [items description]);
            for (PBSourceViewItem * item in items) {
                if (deferredSelectObject = [item findRev:resolvedRev])
                    break;
            }
            NSLog(@"[%@ %s] deferredSelectObject = %@", [self class], _cmd, deferredSelectObject);
        }
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"[%@ %s]", [self class], _cmd);

	if ([@"currentBranchChange" isEqualToString:context]) {
		[sourceView reloadData];
		[self selectCurrentBranch];
		return;
	}

	if ([@"branchesModified" isEqualToString:context]) {
		NSInteger changeKind = [(NSNumber *)[change objectForKey:NSKeyValueChangeKindKey] intValue];

		if (changeKind == NSKeyValueChangeInsertion) {
			NSArray *newRevSpecs = [change objectForKey:NSKeyValueChangeNewKey];
			for (PBGitRevSpecifier *rev in newRevSpecs) {
				[self addRevSpec:rev];
				PBSourceViewItem *item = [self itemForRev:rev];
				[sourceView PBExpandItem:item expandParents:YES];
			}
		}
		else if (changeKind == NSKeyValueChangeRemoval) {
			NSArray *removedRevSpecs = [change objectForKey:NSKeyValueChangeOldKey];
			for (PBGitRevSpecifier *rev in removedRevSpecs)
				[self removeRevSpec:rev];
		}
		return;
	}

	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (PBSourceViewItem *) selectedItem
{
	NSInteger index = [sourceView selectedRow];
	PBSourceViewItem *item = [sourceView itemAtRow:index];

	return item;
}

- (void) selectStage
{
	NSIndexSet *index = [NSIndexSet indexSetWithIndex:[sourceView rowForItem:stage]];
	[sourceView selectRowIndexes:index byExtendingSelection:NO];
}

- (void) selectBranch:(PBSourceViewItem *)branchItem
{
    [sourceView PBExpandItem:branchItem expandParents:YES];
    NSInteger row = [sourceView rowForItem:branchItem];
    NSLog(@"[%@ %s] rowForItem (%@) = %d", [self class], _cmd, branchItem, row);
    NSIndexSet *index = [NSIndexSet indexSetWithIndex:row];
	[sourceView selectRowIndexes:index byExtendingSelection:NO];
}

- (PBSourceViewItem *) itemForRev:(PBGitRevSpecifier *)rev {
	PBSourceViewItem *foundItem = nil;
	for (PBSourceViewItem *item in items) {
        if (foundItem = [item findRev:rev]) {
            NSLog(@"[%@ %s]: found item! Item = %@ for rev = %@", [self class], _cmd, item, rev);
			return foundItem;
        }
    }
	return nil;
}

- (BOOL) selectCommitWithSha:(NSString *)refSHA  {
    NSArray *revList = repository.revisionList.commits;
    NSLog(@"[%@ %s] revList = %@", [self class], _cmd, revList);
    for (PBGitCommit *commit in revList) {
        NSLog(@"[%@ %s] commit = %@", [self class], _cmd, commit);
        if ([[commit realSha] isEqualToString:refSHA]) {
            [historyViewController selectCommit:refSHA];
            return YES;
        }
    }
    return NO;
}

- (void) selectCurrentBranch
{
	PBGitRevSpecifier *rev = repository.currentBranch;

    NSLog(@"[%@ %s] rev = %@", [self class], _cmd, rev);

    if (deferredSelectObject) {
        NSString * sha = [ApplicationController sharedApplicationController].deferredSelectSha;

        if (!sha) {
            sha = [repository shaForRef:[deferredSelectObject.revSpecifier ref]];
        }

        [self selectBranch:deferredSelectObject];
        //[historyViewController selectCommit:sha];
        deferredSelectObject = nil;
        return;
    }

    if (!rev) {
        [repository reloadRefs];
        [repository readCurrentBranch];
        return;
    }
//     else {
//         NSString * refSHA = [repository shaForRef:[rev ref]];
//         if (![self selectCommitWithSha:refSHA]) {
//             [repository reloadRefs];
//             [self selectCommitWithSha:refSHA];
//         }
//     }

    PBSourceViewItem *item = [self itemForRev:rev];

//     if (!item) {
//         // Obviously we havn't found the item so we reset it's isSimpleRef status back to NO
//         // so it will get added to the OTHER group.
//         //[rev setIsSimpleRef:NO];
//         [self addRevSpec:rev];
//         // Try to find the just added item again.
//         item = [self itemForRev:rev];
//     }
    [self selectBranch:item];
}


- (void)addRevSpec:(PBGitRevSpecifier *)rev
{
	if (![rev isSimpleRef]) {
        NSLog(@"[%@ %s]: rev = %@", [self class], _cmd, rev);
		[others addChild:[PBSourceViewItem itemWithRevSpec:rev]];
		[sourceView reloadData];
		return;
	}

	NSArray *pathComponents = [[rev simpleRef] componentsSeparatedByString:@"/"];
	if ([pathComponents count] < 2)
		[branches addChild:[PBSourceViewItem itemWithRevSpec:rev]];
	else if ([[pathComponents objectAtIndex:1] isEqualToString:@"heads"])
		[branches addRev:rev toPath:[pathComponents subarrayWithRange:NSMakeRange(2, [pathComponents count] - 2)]];
	else if ([[rev simpleRef] hasPrefix:@"refs/tags/"])
		[tags addRev:rev toPath:[pathComponents subarrayWithRange:NSMakeRange(2, [pathComponents count] - 2)]];
	else if ([[rev simpleRef] hasPrefix:@"refs/remotes/"])
		[remotes addRev:rev toPath:[pathComponents subarrayWithRange:NSMakeRange(2, [pathComponents count] - 2)]];
	[sourceView reloadData];
}

- (void) removeRevSpec:(PBGitRevSpecifier *)rev
{
	PBSourceViewItem *item = [self itemForRev:rev];

	if (!item)
		return;

	PBSourceViewItem *parent = item.parent;
	[parent removeChild:item];
	[sourceView reloadData];
}

#pragma mark NSOutlineView delegate methods

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger index = [sourceView selectedRow];
	PBSourceViewItem *item = [sourceView itemAtRow:index];

	if ([item revSpecifier]) {
		if (![repository.currentBranch isEqual:[item revSpecifier]])
			repository.currentBranch = [item revSpecifier];
		[superController changeContentController:historyViewController];
		[PBGitDefaults setShowStageView:NO];
	}

	if (item == stage) {
		[superController changeContentController:commitViewController];
		[PBGitDefaults setShowStageView:YES];
	}

	[self updateActionMenu];
	[historyViewController updateRemoteControls:[[self selectedItem] ref]];
}

#pragma mark NSOutlineView delegate methods
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return [item isGroupItem];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(PBSourceViewCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(PBSourceViewItem *)item
{
	cell.isCheckedOut = [item.revSpecifier isEqual:[repository headRef]];

	[cell setImage:[item icon]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ![item isGroupItem];
}

//
// The next method is necessary to hide the triangle for uncollapsible items
// That is, items which should always be displayed, such as the Project group.
// This also moves the group item to the left edge.
- (BOOL) outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
	return ![item isUncollapsible];
}

#pragma mark NSOutlineView Datasource methods

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (!item)
		return [items objectAtIndex:index];

	return [[(PBSourceViewItem *)item children] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [[(PBSourceViewItem *)item children] count];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item)
		return [items count];

	return [[(PBSourceViewItem *)item children] count];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [(PBSourceViewItem *)item title];
}


#pragma mark Menus

- (void) updateActionMenu
{
	[actionButton setEnabled:([[self selectedItem] ref] != nil)];
}

- (void) addMenuItemsForRef:(PBGitRef *)ref toMenu:(NSMenu *)menu
{
	if (!ref)
		return;

	for (NSMenuItem *menuItem in [historyViewController.refController menuItemsForRef:ref])
		[menu addItem:menuItem];
}

- (NSMenuItem *) actionIconItem
{
	NSMenuItem *actionIconItem = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
	NSImage *actionIcon = [NSImage imageNamed:@"NSActionTemplate"];
	[actionIcon setSize:NSMakeSize(12, 12)];
	[actionIconItem setImage:actionIcon];

	return actionIconItem;
}

- (NSMenu *) menuForRow:(NSInteger)row
{
	PBSourceViewItem *viewItem = [sourceView itemAtRow:row];

	PBGitRef *ref = [viewItem ref];
	if (!ref)
		return nil;

	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	[self addMenuItemsForRef:ref toMenu:menu];

	return menu;
}

// delegate of the action menu
- (void) menuNeedsUpdate:(NSMenu *)menu
{
	[actionButton removeAllItems];
	[menu addItem:[self actionIconItem]];

	PBGitRef *ref = [[self selectedItem] ref];
	[self addMenuItemsForRef:ref toMenu:menu];
}

@end
