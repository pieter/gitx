//
//  PBRefMenuItem.m
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBRefMenuItem.h"
#import "PBGitRepository.h"
#import "PBGitRevSpecifier.h"

@implementation PBRefMenuItem
@synthesize refishs;

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


+ (NSArray<NSMenuItem *> *) defaultMenuItemsForStashRef:(PBGitRef *)ref inRepository:(PBGitRepository *)repo target:(id)target
{
    NSMutableArray *items = [NSMutableArray array];
	NSString *targetRefName = [ref shortName];
    BOOL isCleanWorkingCopy = YES;
    
    // pop
    NSString *stashPopTitle = [NSString stringWithFormat:@"Pop %@", targetRefName];
    [items addObject:[PBRefMenuItem itemWithTitle:stashPopTitle action:@selector(stashPop:) enabled:isCleanWorkingCopy]];
    
    // apply
    NSString *stashApplyTitle = @"Apply";
    [items addObject:[PBRefMenuItem itemWithTitle:stashApplyTitle action:@selector(stashApply:) enabled:YES]];
    
    // view diff
    NSString *stashDiffTitle = @"View Diff";
    [items addObject:[PBRefMenuItem itemWithTitle:stashDiffTitle action:@selector(stashViewDiff:) enabled:YES]];

    [items addObject:[PBRefMenuItem separatorItem]];

    // drop
    NSString *stashDropTitle = @"Drop";
    [items addObject:[PBRefMenuItem itemWithTitle:stashDropTitle action:@selector(stashDrop:) enabled:YES]];
    
	for (PBRefMenuItem *item in items) {
		item.target = target;
		item.refishs = @[ref];
	}
    
	return items;
}


+ (NSArray<NSMenuItem *> *) defaultMenuItemsForRef:(PBGitRef *)ref inRepository:(PBGitRepository *)repo target:(id)target
{
	if (!ref || !repo || !target) {
		return nil;
	}
	
    if ([ref isStash]) {
        return [self defaultMenuItemsForStashRef:ref inRepository:repo target:target];
    }

	NSString *refName = [ref shortName];

	PBGitRef *headRef = [[repo headRef] ref];
	NSString *headRefName = [headRef shortName];
	BOOL isHead = [ref isEqualToRef:headRef];
	BOOL isOnHeadBranch = isHead ? YES : [repo isRefOnHeadBranch:ref];
	BOOL isDetachedHead = (isHead && [headRefName isEqualToString:@"HEAD"]);

	NSString *remoteName = [ref remoteName];
	if (!remoteName && [ref isBranch]) {
		remoteName = [[repo remoteRefForBranch:ref error:NULL] remoteName];
	}
	BOOL hasRemote = (remoteName ? YES : NO);
	BOOL isRemote = ([ref isRemote] && ![ref isRemoteBranch]);

	NSMutableArray *items = [NSMutableArray array];
	if (!isRemote) {
		// checkout ref
		NSString *checkoutTitle = [@"Checkout " stringByAppendingString:refName];
		[items addObject:[PBRefMenuItem itemWithTitle:checkoutTitle action:@selector(checkout:) enabled:!isHead]];
		[items addObject:[PBRefMenuItem separatorItem]];

		// create branch
		NSString *createBranchTitle = [ref isRemoteBranch] ? [NSString stringWithFormat:@"Create Branch tracking %@…", refName] : @"Create Branch…";
		[items addObject:[PBRefMenuItem itemWithTitle:createBranchTitle action:@selector(createBranch:) enabled:YES]];

		// create tag
		[items addObject:[PBRefMenuItem itemWithTitle:@"Create Tag…" action:@selector(createTag:) enabled:YES]];

		// view tag info
		if ([ref isTag])
			[items addObject:[PBRefMenuItem itemWithTitle:@"View Tag Info…" action:@selector(showTagInfoSheet:) enabled:YES]];

		// Diff
		NSString *diffTitle = [NSString stringWithFormat:@"Diff with %@", headRefName];
		[items addObject:[PBRefMenuItem itemWithTitle:diffTitle action:@selector(diffWithHEAD:) enabled:!isHead]];
		[items addObject:[PBRefMenuItem separatorItem]];

		// merge ref
		NSString *mergeTitle = isOnHeadBranch ? @"Merge" : [NSString stringWithFormat:@"Merge %@ into %@", refName, headRefName];
		[items addObject:[PBRefMenuItem itemWithTitle:mergeTitle action:@selector(merge:) enabled:!isOnHeadBranch]];

		// rebase
		NSString *rebaseTitle = isOnHeadBranch ? @"Rebase" : [NSString stringWithFormat:@"Rebase %@ on %@", headRefName, refName];
		[items addObject:[PBRefMenuItem itemWithTitle:rebaseTitle action:@selector(rebaseHeadBranch:) enabled:!isOnHeadBranch]];

		[items addObject:[PBRefMenuItem separatorItem]];
	}

	// fetch
	NSString *fetchTitle = hasRemote ? [NSString stringWithFormat:@"Fetch %@", remoteName] : @"Fetch";
	[items addObject:[PBRefMenuItem itemWithTitle:fetchTitle action:@selector(fetchRemote:) enabled:hasRemote]];

	// pull
	NSString *pullTitle = hasRemote ? [NSString stringWithFormat:@"Pull %@ and Update %@", remoteName, headRefName] : @"Pull";
	[items addObject:[PBRefMenuItem itemWithTitle:pullTitle action:@selector(pullRemote:) enabled:hasRemote]];

	// push
	if (isRemote || [ref isRemoteBranch]) {
		// push updates to remote
		NSString *pushTitle = [NSString stringWithFormat:@"Push Updates to %@", remoteName];
		[items addObject:[PBRefMenuItem itemWithTitle:pushTitle action:@selector(pushUpdatesToRemote:) enabled:YES]];
	}
	else if (isDetachedHead) {
		[items addObject:[PBRefMenuItem itemWithTitle:@"Push" action:nil enabled:NO]];
	}
	else {
		// push to default remote
		BOOL hasDefaultRemote = NO;
		if (![ref isTag] && hasRemote) {
			hasDefaultRemote = YES;
			NSString *pushTitle = [NSString stringWithFormat:@"Push %@ to %@", refName, remoteName];
			[items addObject:[PBRefMenuItem itemWithTitle:pushTitle action:@selector(pushDefaultRemoteForRef:) enabled:YES]];
		}

		// push to remotes submenu
		NSArray *remoteNames = [repo remotes];
		if ([remoteNames count] && !(hasDefaultRemote && ([remoteNames count] == 1))) {
			NSString *pushToTitle = [NSString stringWithFormat:@"Push %@ to", refName];
			PBRefMenuItem *pushToItem = [PBRefMenuItem itemWithTitle:pushToTitle action:nil enabled:YES];
			NSMenu *remotesMenu = [[NSMenu alloc] initWithTitle:@"remotesMenu"];
			for (NSString *remote in remoteNames) {
				PBRefMenuItem *remoteItem = [PBRefMenuItem itemWithTitle:remote action:@selector(pushToRemote:) enabled:YES];
				remoteItem.target = target;
				remoteItem.refishs = @[ref];
				remoteItem.representedObject = remote;
				[remotesMenu addItem:remoteItem];
			}
			[pushToItem setSubmenu:remotesMenu];
			[items addObject:pushToItem];
		}
	}

	// delete ref
	[items addObject:[PBRefMenuItem separatorItem]];
	{
		BOOL isStash = [[ref ref] hasPrefix:@"refs/stash"];
		NSString *deleteTitle = [NSString stringWithFormat:@"Delete %@…", refName];
		if ([ref isRemote]) {
			deleteTitle = [NSString stringWithFormat:@"Remove %@…", refName];
		}
		BOOL deleteEnabled = !(isDetachedHead || isHead || isStash);
		PBRefMenuItem *deleteItem = [PBRefMenuItem itemWithTitle:deleteTitle action:@selector(showDeleteRefSheet:) enabled:deleteEnabled];
		[items addObject:deleteItem];
	}

	for (PBRefMenuItem *item in items) {
		item.target = target;
		item.refishs = @[ref];
	}

	return items;
}


+ (NSArray<NSMenuItem *> *) defaultMenuItemsForCommits:(NSArray<PBGitCommit *> *)commits target:(id)target
{
	NSMutableArray *items = [NSMutableArray array];
	
	BOOL isSingleCommitSelection = commits.count == 1;
	PBGitCommit *firstCommit = commits.firstObject;
	
	NSString *headBranchName = [[[firstCommit.repository headRef] ref] shortName];
	BOOL isOnHeadBranch = [firstCommit isOnHeadBranch];
	BOOL isHead = [firstCommit.OID isEqual:firstCommit.repository.headOID];

	if (isSingleCommitSelection) {
		[items addObject:[PBRefMenuItem itemWithTitle:@"Checkout Commit" action:@selector(checkout:) enabled:YES]];
		[items addObject:[PBRefMenuItem separatorItem]];

		[items addObject:[PBRefMenuItem itemWithTitle:@"Create Branch…" action:@selector(createBranch:) enabled:YES]];
		[items addObject:[PBRefMenuItem itemWithTitle:@"Create Tag…" action:@selector(createTag:) enabled:YES]];
		[items addObject:[PBRefMenuItem separatorItem]];
	}
	
	[items addObject:[PBRefMenuItem itemWithTitle:@"Copy SHA" action:@selector(copySHA:) enabled:YES]];
	[items addObject:[PBRefMenuItem itemWithTitle:@"Copy short SHA" action:@selector(copyShortSHA:) enabled:YES]];
	[items addObject:[PBRefMenuItem itemWithTitle:@"Copy Patch" action:@selector(copyPatch:) enabled:YES]];

	if (isSingleCommitSelection) {
		NSString *diffTitle = [NSString stringWithFormat:@"Diff with %@", headBranchName];
		[items addObject:[PBRefMenuItem itemWithTitle:diffTitle action:@selector(diffWithHEAD:) enabled:!isHead]];
		[items addObject:[PBRefMenuItem separatorItem]];

		// merge commit
		NSString *mergeTitle = isOnHeadBranch ? @"Merge Commit" : [NSString stringWithFormat:@"Merge Commit into %@", headBranchName];
		[items addObject:[PBRefMenuItem itemWithTitle:mergeTitle action:@selector(merge:) enabled:!isOnHeadBranch]];

		// cherry pick
		NSString *cherryPickTitle = isOnHeadBranch ? @"Cherry Pick Commit" : [NSString stringWithFormat:@"Cherry Pick Commit to %@", headBranchName];
		[items addObject:[PBRefMenuItem itemWithTitle:cherryPickTitle action:@selector(cherryPick:) enabled:!isOnHeadBranch]];

		// rebase
		NSString *rebaseTitle = isOnHeadBranch ? @"Rebase Commit" : [NSString stringWithFormat:@"Rebase %@ on Commit", headBranchName];
		[items addObject:[PBRefMenuItem itemWithTitle:rebaseTitle action:@selector(rebaseHeadBranch:) enabled:!isOnHeadBranch]];
	}
	
	for (PBRefMenuItem *item in items) {
		item.target = target;
		item.refishs = commits;
	}

	return items;
}


@end
