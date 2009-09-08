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

- (void)addChild:(PBSourceViewItem *)child
{
	[self.children addObject:child];
}

- (NSString *)title
{
	if (title)
		return title;
	
	return [revSpecifier description];
}

@end
