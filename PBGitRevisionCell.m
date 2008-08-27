//
//  PBGitRevisionCell.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRevisionCell.h"


@implementation PBGitRevisionCell

@synthesize cellInfo;
-(void) setCellInfo: (PBGraphCellInfo*) info
{
	isReady = YES;
	cellInfo = info;
}

- (id) initWithCoder: (id) coder
{
	self = [super initWithCoder:coder];
	if (self != nil) {
		isReady = NO;
	}
	return self;
}

- (NSArray*) colors
{
	return 	[NSArray arrayWithObjects:[NSColor redColor], [NSColor blueColor],
			[NSColor orangeColor], [NSColor blackColor], [NSColor greenColor], nil];
}

- (void) drawLineFromColumn: (int) from toColumn: (int) to inRect: (NSRect) r offset: (int) offset
{

	int columnWidth = 10;
	NSPoint origin = r.origin;
	
	NSPoint source = NSMakePoint(origin.x + columnWidth* from, origin.y + offset);
	NSPoint center = NSMakePoint( origin.x + columnWidth * to, origin.y + r.size.height * 0.5);

	// Just use red for now.
	[[[self colors] objectAtIndex:0] set];
	
	NSBezierPath * path = [NSBezierPath bezierPath];
	[path setLineWidth:2];
	
	[path moveToPoint: source];
	[path lineToPoint: center];
	[path stroke];
	
}

- (void) drawCircleForColumn: (int) c inRect: (NSRect) r
{
	NSArray* col = [NSArray arrayWithObjects:[NSColor redColor], [NSColor blueColor],
	[NSColor orangeColor], [NSColor blackColor], [NSColor greenColor], nil];

	int columnWidth = 10;
	NSPoint origin = r.origin;
	NSPoint columnOrigin = { origin.x + columnWidth * c, origin.y};
	
	NSRect oval = { columnOrigin.x - 5, columnOrigin.y + r.size.height * 0.5 - 5, 10, 10};

	
	NSBezierPath * path = [NSBezierPath bezierPath];
	path = [NSBezierPath bezierPathWithOvalInRect:oval];
	//[[col objectAtIndex:cellInfo.columns[c].color] set];
	[path fill];
	
	NSRect smallOval = { columnOrigin.x - 3, columnOrigin.y + r.size.height * 0.5 - 3, 6, 6};
	[[NSColor whiteColor] set];
	path = [NSBezierPath bezierPathWithOvalInRect:smallOval];
	[path fill];	
}

- (void) drawWithFrame: (NSRect) rect inView:(NSView *)view
{
	if (!isReady)
		return [super drawWithFrame:rect inView:view];

	float pathWidth = 10 + 10 * cellInfo.numColumns;

	NSRect ownRect;
	NSDivideRect(rect, &ownRect, &rect, pathWidth, NSMinXEdge);

	for (PBGitGraphLine* line in cellInfo.lines) {
		if (line.upper == 0)
			[self drawLineFromColumn: line.from toColumn: line.to inRect:ownRect offset: ownRect.size.height];
		else
			[self drawLineFromColumn:line.from toColumn: line.to inRect:ownRect offset: 0];
	}

	[self drawCircleForColumn: cellInfo.position inRect: ownRect];

	
	[super drawWithFrame:rect inView:view];
	isReady = NO;
}

@end
