//
//  PBGitSidebar.m
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PBGitSidebarController.h"
#import "PBSourceViewItem.h"
#import "NSOutlineViewExt.h"
#import "PBSourceViewAction.h"

@interface PBGitSidebarController ()

- (void)populateList;
- (void)updateSelection;
- (void)addRevSpec:(PBGitRevSpecifier *)revSpec;
@end

@implementation PBGitSidebarController
@synthesize items;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller
{
	self = [super initWithRepository:theRepository superController:controller];
	[sourceView setDelegate:self];
	items = [NSMutableArray array];

	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	window.contentView = self.view;
	[self populateList];

	[repository addObserver:self forKeyPath:@"currentBranch" options:0 context:@"currentBranchChange"];
	[self updateSelection];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([@"currentBranchChange" isEqualTo:context])
		[self updateSelection];		
}

- (void)updateSelection
{
	PBGitRevSpecifier *rev = repository.currentBranch;
	if (!rev)
		return;
	
	PBSourceViewItem *item = nil;
	for (PBSourceViewItem *it in items)
		if (item = [it findRev:rev])
			break;
	
	if (!item) {
		[self addRevSpec:rev];
		// Try to find the just added item again.
		// TODO: refactor with above.
		for (PBSourceViewItem *it in items)
			if (item = [it findRev:rev])
				break;
	}
	
	[sourceView PBExpandItem:item expandParents:YES];
	NSInteger index = [sourceView rowForItem:item];
	
	[sourceView selectRow:index byExtendingSelection:NO];
}

- (void)addRevSpec:(PBGitRevSpecifier *)rev
{
	if (![rev isSimpleRef]) {
		[custom addChild:[PBSourceViewItem itemWithRevSpec:rev]];
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
}

#pragma mark NSOutlineView delegate methods

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger index = [sourceView selectedRow];
	PBSourceViewItem *item = [sourceView itemAtRow:index];

	if ([item revSpecifier]) {
		[[repository windowController] showHistoryView:self];
		repository.currentBranch = [item revSpecifier];
		return;
	}

	if (item == commitAction)
		[[repository windowController] showCommitView:self];

	/* ... */

	
	/* Handle Remotes */
}

#pragma mark NSOutlineView delegate methods
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return [item isGroupItem];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setImage:[item icon]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ![item isGroupItem];
}

//
// The next two methods are necessary to hide the triangle for uncollapsible items
// That is, items which should always be displayed, such as the action items.
//
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
	return !([item isUncollapsible]);
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setTransparent:[item isUncollapsible]];
} 

- (void)populateList
{
	PBSourceViewItem *actions = [PBSourceViewItem groupItemWithTitle:@"Actions"];

	actions.isUncollapsible = YES;

	commitAction = [PBSourceViewAction itemWithTitle:@"Index / Commit"];
	commitAction.icon = [NSImage imageNamed:@"CommitViewTemplate"];
	[actions addChild:commitAction];
	
	branches = [PBSourceViewItem groupItemWithTitle:@"Branches"];
	remotes = [PBSourceViewItem groupItemWithTitle:@"Remotes"];
	tags = [PBSourceViewItem groupItemWithTitle:@"Tags"];
	custom = [PBSourceViewItem groupItemWithTitle:@"Custom"];

	for (PBGitRevSpecifier *rev in repository.branches)
		[self addRevSpec:rev];

	//[items addObject:actions];

	[items addObject:branches];
	[items addObject:remotes];
	[items addObject:tags];
	[items addObject:custom];

	[sourceView reloadData];
	[sourceView expandItem:branches expandChildren:YES];
	[sourceView expandItem:actions];

	NSAssert(branches == [sourceView itemAtRow:0], @"First item is not the Branches");
	[sourceView reloadItem:nil reloadChildren:YES];

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

@end
