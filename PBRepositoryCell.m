//
//  PBRepositoryCell.m
//  GitX
//
//  Created by Pieter de Bie on 9/14/09.
//  Copyright 2009 Pieter de Bie. All rights reserved.
//

#import "PBRepositoryCell.h"


@implementation PBRepositoryCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect nameRect, pathRect;
	cellFrame = NSInsetRect(cellFrame, 5, 0);
	NSDivideRect(cellFrame, &nameRect, &pathRect, 35, NSMinYEdge);

	NSMutableDictionary *nameAttributes = [NSMutableDictionary dictionary];
	NSMutableDictionary *pathAttributes = [NSMutableDictionary dictionary];

	[nameAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:28] forKey:NSFontAttributeName];
	[pathAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:12] forKey:NSFontAttributeName];

	if ([self isHighlighted]) {
		[nameAttributes setObject:[NSColor selectedTextColor] forKey:NSForegroundColorAttributeName];
		[pathAttributes setObject:[NSColor alternateSelectedControlTextColor] forKey:NSForegroundColorAttributeName];
	} else {
		[pathAttributes setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	}

	[[[self objectValue] lastPathComponent] drawInRect:nameRect withAttributes:nameAttributes];
	[[self objectValue] drawInRect:pathRect withAttributes:pathAttributes];		
}

@end
