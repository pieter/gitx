//
//  PBRefMenuItem.m
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBRefMenuItem.h"


@implementation PBRefMenuItem
@synthesize refish;

+ (PBRefMenuItem *) itemWithTitle:(NSString *)title action:(SEL)selector enabled:(BOOL)isEnabled
{
	if (!isEnabled)
		selector = nil;

	PBRefMenuItem *item = [[PBRefMenuItem alloc] initWithTitle:title action:selector keyEquivalent:@""];
	[item setEnabled:isEnabled];
	return item;
}


+ (PBRefMenuItem *) separatorItem
{
	PBRefMenuItem *item = (PBRefMenuItem *)[super separatorItem];
	return item;
}


+ (NSArray *) defaultMenuItemsForRef:(PBGitRef *)ref inRepository:(PBGitRepository *)repo target:(id)target
{
	if (!ref || !repo || !target) {
		return nil;
	}

	NSMutableArray *items = [NSMutableArray array];

	NSString *targetRefName = [ref shortName];
	PBGitCommit *commit = [repo commitForRef:ref];
	BOOL isOnHeadBranch = [commit isOnHeadBranch];

	PBGitRef *headRef = [[repo headRef] ref];
	NSString *headRefName = [headRef shortName];
	BOOL isHead = [ref isEqualToRef:headRef];

	// checkout ref
	NSString *checkoutTitle = [@"Checkout " stringByAppendingString:targetRefName];
	[items addObject:[PBRefMenuItem itemWithTitle:checkoutTitle action:@selector(checkout:) enabled:!isHead]];
	[items addObject:[PBRefMenuItem separatorItem]];

	// create branch
	[items addObject:[PBRefMenuItem itemWithTitle:@"Create branch…" action:@selector(createBranch:) enabled:YES]];

	// create tag
	[items addObject:[PBRefMenuItem itemWithTitle:@"Create Tag…" action:@selector(createTag:) enabled:YES]];

	// view tag info
	if ([ref isTag])
		[items addObject:[PBRefMenuItem itemWithTitle:@"View tag info…" action:@selector(showTagInfoSheet:) enabled:YES]];
	[items addObject:[PBRefMenuItem separatorItem]];

    // merge ref
	NSString *mergeTitle = isOnHeadBranch ? @"Merge" : [NSString stringWithFormat:@"Merge %@ into %@", targetRefName, headRefName];
    [items addObject:[PBRefMenuItem itemWithTitle:mergeTitle action:@selector(merge:) enabled:!isOnHeadBranch]];

    // rebase
	NSString *rebaseTitle = isOnHeadBranch ? @"Rebase" : [NSString stringWithFormat:@"Rebase %@ on %@", headRefName, targetRefName];
    [items addObject:[PBRefMenuItem itemWithTitle:rebaseTitle action:@selector(rebaseHeadBranch:) enabled:!isOnHeadBranch]];

	// delete ref
	[items addObject:[PBRefMenuItem separatorItem]];
	NSString *deleteTitle = [NSString stringWithFormat:@"Delete %@…", targetRefName];
	[items addObject:[PBRefMenuItem itemWithTitle:deleteTitle action:@selector(showDeleteRefSheet:) enabled:YES]];

	for (PBRefMenuItem *item in items) {
		[item setTarget:target];
		[item setRefish:ref];
	}

	return items;
}


+ (NSArray *) defaultMenuItemsForCommit:(PBGitCommit *)commit target:(id)target
{
	NSMutableArray *items = [NSMutableArray array];

	NSString *headBranchName = [[[commit.repository headRef] ref] shortName];
	BOOL isOnHeadBranch = [commit isOnHeadBranch];

	[items addObject:[PBRefMenuItem itemWithTitle:@"Checkout Commit" action:@selector(checkout:) enabled:YES]];
	[items addObject:[PBRefMenuItem separatorItem]];

    [items addObject:[PBRefMenuItem itemWithTitle:@"Create Branch…" action:@selector(createBranch:) enabled:YES]];
	[items addObject:[PBRefMenuItem itemWithTitle:@"Create Tag…" action:@selector(createTag:) enabled:YES]];
	[items addObject:[PBRefMenuItem separatorItem]];

	[items addObject:[PBRefMenuItem itemWithTitle:@"Copy SHA" action:@selector(copySHA:) enabled:YES]];
	[items addObject:[PBRefMenuItem itemWithTitle:@"Copy Patch" action:@selector(copyPatch:) enabled:YES]];
	[items addObject:[PBRefMenuItem separatorItem]];

	// merge commit
	NSString *mergeTitle = isOnHeadBranch ? @"Merge commit" : [NSString stringWithFormat:@"Merge commit into %@", headBranchName];
	[items addObject:[PBRefMenuItem itemWithTitle:mergeTitle action:@selector(merge:) enabled:!isOnHeadBranch]];

	// cherry pick
	NSString *cherryPickTitle = isOnHeadBranch ? @"Cherry pick commit" : [NSString stringWithFormat:@"Cherry pick commit to %@", headBranchName];
	[items addObject:[PBRefMenuItem itemWithTitle:cherryPickTitle action:@selector(cherryPick:) enabled:!isOnHeadBranch]];

	// rebase
	NSString *rebaseTitle = isOnHeadBranch ? @"Rebase commit" : [NSString stringWithFormat:@"Rebase %@ on commit", headBranchName];
	[items addObject:[PBRefMenuItem itemWithTitle:rebaseTitle action:@selector(rebaseHeadBranch:) enabled:!isOnHeadBranch]];

	for (PBRefMenuItem *item in items) {
		[item setTarget:target];
		[item setRefish:commit];
	}

	return items;
}


@end
