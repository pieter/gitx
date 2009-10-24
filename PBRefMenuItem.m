//
//  PBRefMenuItem.m
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBRefMenuItem.h"


@implementation PBRefMenuItem
@synthesize ref, commit;

+ (NSArray *)defaultMenuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit target:(id)target
{
	NSMutableArray *array = [NSMutableArray array];
	NSString *type = [ref type];
	if ([type isEqualToString:@"remote"])
		type = @"remote branch";
	else if ([type isEqualToString:@"head"])
		type = @"branch";

	NSString *remote = [[[commit repository] config] valueForKeyPath:[NSString stringWithFormat:@"branch.%@.remote", [ref shortName]]];
	bool has_remote = remote != NULL;

	if ([type isEqualToString:@"branch"]) {
		PBRefMenuItem *push = [[PBRefMenuItem alloc] initWithTitle:@"Push branch"
															action:@selector(pushRef:)
													 keyEquivalent: @""];
		if(!has_remote) [push setEnabled:NO];
		[array addObject:push];
	}

	if ([type isEqualToString:@"branch"])
		[array addObject:[[PBRefMenuItem alloc] initWithTitle:@"Checkout branch"
													   action:@selector(checkoutRef:)
												keyEquivalent: @""]];

	[array addObject:[[PBRefMenuItem alloc] initWithTitle:[@"Delete " stringByAppendingString:type]
												   action:@selector(removeRef:)
											keyEquivalent: @""]];
    if ([type isEqualToString:@"tag"])
		[array addObject:[[PBRefMenuItem alloc] initWithTitle:@"View tag info"
													   action:@selector(tagInfo:)
												keyEquivalent: @""]];    
	
	for (PBRefMenuItem *item in array)
	{
		[item setTarget: target];
		[item setRef: ref];
		[item setCommit:commit];
	}

	return array;
}
@end
