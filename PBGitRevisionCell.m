//
//  PBGitRevisionCell.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRevisionCell.h"


@implementation NSBezierPath (RoundedRectangle)
+ (NSBezierPath *)bezierPathWithRoundedRect: (NSRect) aRect cornerRadius: (double) cRadius
{
	double left = aRect.origin.x, bottom = aRect.origin.y, width = aRect.size.width, height = aRect.size.height;

	//now, crop the radius so we don't get weird effects
	double lesserDim = width < height ? width : height;
	if ( cRadius > lesserDim / 2 )
	{
		cRadius = lesserDim / 2;
	}

	//these points describe the rectangle as start and stop points of the
	//arcs making up its corners --points c, e, & g are implicit endpoints of arcs
	//and are unnecessary
	NSPoint a = NSMakePoint( 0, cRadius ), b = NSMakePoint( 0, height - cRadius ),
		d = NSMakePoint( width - cRadius, height ), f = NSMakePoint( width, cRadius ),
		h = NSMakePoint( cRadius, 0 );

	//these points describe the center points of the corner arcs
	NSPoint cA = NSMakePoint( cRadius, height - cRadius ),
		cB = NSMakePoint( width - cRadius, height - cRadius ),
		cC = NSMakePoint( width - cRadius, cRadius ),
		cD = NSMakePoint( cRadius, cRadius );

	//start
	NSBezierPath *bp = [NSBezierPath bezierPath];
	[bp moveToPoint: a ];
	[bp lineToPoint: b ];
	[bp appendBezierPathWithArcWithCenter: cA radius: cRadius startAngle:180 endAngle:90 clockwise: YES];
	[bp lineToPoint: d ];
	[bp appendBezierPathWithArcWithCenter: cB radius: cRadius startAngle:90 endAngle:0 clockwise: YES];
	[bp lineToPoint: f ];
	[bp appendBezierPathWithArcWithCenter: cC radius: cRadius startAngle:0 endAngle:270 clockwise: YES];
	[bp lineToPoint: h ];
	[bp appendBezierPathWithArcWithCenter: cD radius: cRadius startAngle:270 endAngle:180 clockwise: YES];	
	[bp closePath];

	//Transform path to rectangle's origin
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy: left yBy: bottom];
	[bp transformUsingAffineTransform: transform];

	return bp; //it's already been autoreleased
}
@end

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
	static const float ref_padding = 10.0f;
	static const float ref_spacing = 2.0f;

	NSRect refRect = (NSRect){rect->origin, rect->size};

	if([self isHighlighted])
		[[NSColor whiteColor] setStroke];
	else
		[[NSColor blackColor] setStroke];

	int index;
	for (index = 0; index < [cellInfo.refs count]; ++index) {
		NSString* ref    = [cellInfo.refs objectAtIndex:index];
		NSString* newRef = [[ref componentsSeparatedByString:@"/"] lastObject];

		NSSize refSize = [newRef sizeWithAttributes:nil];

		refRect.size.width = refSize.width + ref_padding;

		NSMutableDictionary *attributes = [[[NSMutableDictionary alloc] initWithCapacity:2] autorelease];
		NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[style setAlignment:NSCenterTextAlignment];
		[attributes setObject:style forKey:NSParagraphStyleAttributeName];
		if([self isHighlighted])
			[attributes setObject:[NSColor alternateSelectedControlTextColor] forKey:NSForegroundColorAttributeName];
		[newRef drawInRect:refRect withAttributes:attributes];

		[[NSBezierPath bezierPathWithRoundedRect:refRect cornerRadius:2.0f] stroke];

		refRect.origin.x += refRect.size.width + ref_spacing;
	}

	rect->size.width -= refRect.origin.x - rect->origin.x;
	rect->origin.x    = refRect.origin.x;
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
