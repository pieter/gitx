//
//  PBGitRevisionCell.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRevisionCell.h"


@implementation PBGitRevisionCell
@synthesize commit;

- (void) drawWithFrame: (NSRect) rect inView:(NSView *)view
{
	float pathWidth = 20;

	NSRect ownRect;
	NSDivideRect(rect, &ownRect, &rect, pathWidth, NSMinXEdge);

	// Adjust by removing the border
	ownRect.size.height += 2;
	ownRect.origin.y -= 1;
	
	NSPoint origin = ownRect.origin;
	NSPoint middle = { origin.x + pathWidth / 2, origin.y + ownRect.size.height * 0.5 };

	[[NSColor redColor] set];
	NSBezierPath * path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(middle.x, origin.y)];
	[path setLineWidth:2];
	[path lineToPoint: NSMakePoint(middle.x, origin.y + ownRect.size.height)];
	[path stroke];
	[path setLineWidth:1];
	

	NSRect oval = { middle.x - 5, middle.y -5, 10, 10};
	[[NSColor orangeColor] set];
	path = [NSBezierPath bezierPathWithOvalInRect:oval];
	[path fill];

	if ([self.commit intValue] == 0)
		[[NSColor redColor] set];
	else
		[[NSColor blueColor] set];
	
	[path stroke];
	
	NSRect smallOval = { middle.x - 3, middle.y - 3, 6, 6};
	[[NSColor whiteColor] set];
	path = [NSBezierPath bezierPathWithOvalInRect:smallOval];
	[path fill];
	[[NSColor blackColor] set];
	[path stroke];
	
	
	[super drawWithFrame:rect inView:view];
	[[NSColor blueColor] set];	
	//[path stroke];
}

@end
