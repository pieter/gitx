//
//  PBSourceViewItem.m
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PBSourceViewItem.h"


@implementation PBSourceViewItem
@synthesize name;
@dynamic children;

- (id)initWithName:(NSString *)aName
{
	if (!(self = [super init]))
		return nil;

	name = aName;
	return self;
}

- (NSArray *)children
{
	return [NSArray array];
}
@end
