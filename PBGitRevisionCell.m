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
	return 	[NSArray arrayWithObjects:
				[NSColor colorWithCalibratedRed: 0X4e/256.0 green:0X9A/256.0 blue: 0X06/256.0 alpha: 1.0],
				[NSColor colorWithCalibratedRed: 0X20/256.0 green:0X4A/256.0 blue: 0X87/256.0 alpha: 1.0],
				[NSColor colorWithCalibratedRed: 0XC4/256.0 green:0XA0/256.0 blue: 0 alpha: 1.0],
				[NSColor colorWithCalibratedRed: 0X5C/256.0 green:0X35/256.0 blue: 0X66/256.0 alpha: 1.0],
				[NSColor colorWithCalibratedRed: 0XA4/256.0 green:0X00/256.0 blue: 0X00/256.0 alpha: 1.0],
				[NSColor colorWithCalibratedRed: 0XCE/256.0 green:0X5C/256.0 blue: 0 alpha: 1.0],
				nil];
}

- (void) drawLineFromColumn: (int) from toColumn: (int) to inRect: (NSRect) r offset: (int) offset color: (int) c
{

	int columnWidth = 10;
	NSPoint origin = r.origin;
	
	NSPoint source = NSMakePoint(origin.x + columnWidth* from, origin.y + offset);
	NSPoint center = NSMakePoint( origin.x + columnWidth * to, origin.y + r.size.height * 0.5);

	// Just use red for now.
	NSArray* colors = [self colors];
	[[colors objectAtIndex: c % [colors count]] set];
	
	NSBezierPath * path = [NSBezierPath bezierPath];
	[path setLineWidth:2];
	
	[path moveToPoint: source];
	[path lineToPoint: center];
	[path stroke];
	
}

- (void) drawCircleForColumn: (int) c inRect: (NSRect) r
{
	if (!cellInfo.refs)
		[[NSColor blackColor] set];
	else
		[[NSColor redColor] set];

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

- (void) drawRefsInRect: (NSRect*) rect
{
	int pathWidth = 40 * [cellInfo.refs count];
	NSRect ownRect;
	NSDivideRect(*rect, &ownRect, rect, pathWidth, NSMinXEdge);	
	for (NSString* ref in cellInfo.refs) {
		NSString* newRef = [[ref componentsSeparatedByString:@"/"] lastObject];
		[newRef drawInRect: ownRect withAttributes:nil];
	}
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
			[self drawLineFromColumn: line.from toColumn: line.to inRect:ownRect offset: ownRect.size.height color: line.colorIndex];
		else
			[self drawLineFromColumn: line.from toColumn: line.to inRect:ownRect offset: 0 color:line.colorIndex];
	}

	[self drawCircleForColumn: cellInfo.position inRect: ownRect];

	if (cellInfo.refs)
		[self drawRefsInRect:&rect];
	
	[super drawWithFrame:rect inView:view];
	isReady = NO;
}

@end
