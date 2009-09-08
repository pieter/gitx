//
//  PBSourceViewItem.m
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PBSourceViewItem.h"
#import "PBGitRevSpecifier.h"

@implementation PBSourceViewItem
@synthesize title, isGroupItem, children, revSpecifier;

- (id)init
{
	if (!(self = [super init]))
		return nil;

	children = [NSMutableArray array];
	return self;
}

+ (PBSourceViewItem *)groupItemWithTitle:(NSString *)title
{
	PBSourceViewItem *item = [[PBSourceViewItem alloc] init];
	item.title = title;
	item.isGroupItem = YES;
	return item;
}

+ (PBSourceViewItem *)itemWithRevSpec:(PBGitRevSpecifier *)revSpecifier
{
	PBSourceViewItem *item = [[PBSourceViewItem alloc] init];
	item.revSpecifier = revSpecifier;

	return item;	
}

+ (PBSourceViewItem *)itemWithTitle:(NSString *)title;
{
	PBSourceViewItem *item = [[PBSourceViewItem alloc] init];
	item.title = title;
	return item;
}

- (void)addChild:(PBSourceViewItem *)child
{
	[self.children addObject:child];
}

- (void)addRev:(PBGitRevSpecifier *)theRevSpecifier toPath:(NSArray *)path
{
	if ([path count] == 1) {
		PBSourceViewItem *item = [PBSourceViewItem itemWithRevSpec:theRevSpecifier];
		[self addChild:item];
		return;
	}

	NSString *firstTitle = [path objectAtIndex:0];
	PBSourceViewItem *node = nil;
	for (PBSourceViewItem *child in [self children])
		if ([child.title isEqualToString:firstTitle])
			node = child;

	if (!node) {
		node = [PBSourceViewItem itemWithTitle:firstTitle];
		[self addChild:node];
	}

	[node addRev:theRevSpecifier toPath:[path subarrayWithRange:NSMakeRange(1, [path count] - 1)]];
}

- (NSString *)title
{
	if (title)
		return title;
	
	return [[revSpecifier description] lastPathComponent];
}

@end
