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
-(void) setCellInfo: (PBGitCellInfo) info
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
	[[col objectAtIndex:cellInfo.columns[c].color] set];
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

	// Adjust by removing the border
	ownRect.size.height += 2;
	ownRect.origin.y -= 1;
	ownRect.origin.x += 10;
	
	int column = 0;

	// We can't iterate over numColumns here, as there may be connections to be drawn outside our columns.
	for (column = 0; column < PBGitMaxColumns; column++) {
		if (cellInfo.upperMapping[column] !=-1)
			[self drawLineFromColumn:column toColumn: cellInfo.upperMapping[column] inRect:ownRect offset: 0];
		if (cellInfo.lowerMapping[column] !=-1)
			[self drawLineFromColumn: column toColumn: cellInfo.lowerMapping[column] inRect:ownRect offset: ownRect.size.height];
	}

	[self drawCircleForColumn: cellInfo.position inRect: ownRect];

	
	[super drawWithFrame:rect inView:view];
	isReady = NO;
}

@end
