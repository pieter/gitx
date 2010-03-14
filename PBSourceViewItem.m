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
@synthesize parent, title, isGroupItem, children, revSpecifier, isUncollapsible;

- (id)init
{
	if (!(self = [super init]))
		return nil;

	children = [NSMutableArray array];
	return self;
}

+ (id)groupItemWithTitle:(NSString *)title
{
	PBSourceViewItem *item = [[[self class] alloc] init];
	item.title = title;
	item.isGroupItem = YES;
	return item;
}

+ (id)itemWithRevSpec:(PBGitRevSpecifier *)revSpecifier
{
	PBSourceViewItem *item = [[[self class] alloc] init];
	item.revSpecifier = revSpecifier;

	return item;	
}

+ (id)itemWithTitle:(NSString *)title;
{
	PBSourceViewItem *item = [[[self class] alloc] init];
	item.title = title;
	return item;
}

- (void)addChild:(PBSourceViewItem *)child
{
	[self.children addObject:child];
	child.parent = self;
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

- (PBSourceViewItem *)findRev:(PBGitRevSpecifier *)rev
{
	if (rev == revSpecifier)
		return self;

	PBSourceViewItem *item = nil;
	for (PBSourceViewItem *child in children)
		if (item = [child findRev:rev])
			return item;

	return nil;
}

- (NSString *)title
{
	if (title)
		return title;
	
	return [[revSpecifier description] lastPathComponent];
}

- (NSImage *)icon
{
	if ([self isGroupItem])
		return nil;

	if (self.parent && !self.parent.parent && [self.parent.title isEqualToString:@"Remotes"])
		return [NSImage imageNamed:@"remote"];

	if (self.parent && !self.parent.parent && [self.parent.title isEqualToString:@"Tags"])
		return [NSImage imageNamed:@"tag"];

	if ([[self children] count])
		return [NSImage imageNamed:@"folder"];

	return [NSImage imageNamed:@"branch"];
}

@end
