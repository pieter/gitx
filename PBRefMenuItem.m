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

	PBGitRef *headRef = [[repo headRef] ref];
	BOOL isHead = [ref isEqualToRef:headRef];

	// checkout ref
	NSString *checkoutTitle = [@"Checkout " stringByAppendingString:targetRefName];
	[items addObject:[PBRefMenuItem itemWithTitle:checkoutTitle action:@selector(checkoutRef:) enabled:!isHead]];

	// view tag info
	if ([ref isTag])
		[items addObject:[PBRefMenuItem itemWithTitle:@"View tag info" action:@selector(tagInfo:) enabled:YES]];

	// delete ref
	[items addObject:[PBRefMenuItem separatorItem]];
	NSString *deleteTitle = [NSString stringWithFormat:@"Delete %@…", targetRefName];
	[items addObject:[PBRefMenuItem itemWithTitle:deleteTitle action:@selector(removeRef:) enabled:YES]];

	for (PBRefMenuItem *item in items) {
		[item setTarget:target];
		[item setRefish:ref];
	}

	return items;
}


+ (NSArray *) defaultMenuItemsForCommit:(PBGitCommit *)commit target:(id)target
{
	NSMutableArray *items = [NSMutableArray array];

	for (PBRefMenuItem *item in items) {
		[item setTarget:target];
		[item setRefish:commit];
	}

	return items;
}


@end
