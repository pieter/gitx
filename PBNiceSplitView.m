//
//  PBNiceSplitView.m
//  GitX
//
//  Created by Pieter de Bie on 31-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBNiceSplitView.h"

static NSImage *bar;
static NSImage *grip;

@implementation PBNiceSplitView

+(void) initialize
{
	NSString *barPath = [[NSBundle mainBundle] pathForResource:@"mainSplitterBar" ofType:@"tiff"];
	bar = [[NSImage alloc] initWithContentsOfFile: barPath];
	[bar setFlipped: YES];

	NSString *gripPath = [[NSBundle mainBundle] pathForResource:@"mainSplitterDimple" ofType:@"tiff"];
	grip = [[NSImage alloc] initWithContentsOfFile: gripPath];
	[grip setFlipped: YES];
}

- (void)drawDividerInRect:(NSRect)aRect
{
	// Draw bar and grip onto the canvas
	NSRect gripRect = aRect;
	gripRect.origin.x = (NSMidX(aRect) - ([grip size].width/2));
	gripRect.size.width = 8;
	
	[self lockFocus];
	[bar drawInRect:aRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[grip drawInRect:gripRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[self unlockFocus];
}

- (CGFloat)dividerThickness
{
	return 10.0;
}

- (void) restoreDefault: (NSString *) defaultName
{
	NSString * string = [[NSUserDefaults standardUserDefaults] objectForKey: defaultName];

	if (string == nil)
		return;		// there was no saved default

	NSScanner* scanner = [NSScanner scannerWithString: string];
	NSRect r0, r1;

	BOOL didScan =
	[scanner scanFloat: &(r0.origin.x)]		&&
	[scanner scanFloat: &(r0.origin.y)]		&&
	[scanner scanFloat: &(r0.size.width)]	&&
	[scanner scanFloat: &(r0.size.height)]	&&
	[scanner scanFloat: &(r1.origin.x)]		&&
	[scanner scanFloat: &(r1.origin.y)]		&&
	[scanner scanFloat: &(r1.size.width)]	&&
	[scanner scanFloat: &(r1.size.height)];

	if (didScan == NO)
		return;	// probably should throw an exception at this point

	[[[self subviews] objectAtIndex: 0] setFrame: r0];
	[[[self subviews] objectAtIndex: 1] setFrame: r1];

	[self adjustSubviews];
}

- (void) saveDefault: (NSString *) defaultName
{
	NSRect r0 = [[[self subviews] objectAtIndex: 0] frame];
	NSRect r1 = [[[self subviews] objectAtIndex: 1] frame];

	NSString * string = [NSString stringWithFormat: @"%f %f %f %f %f %f %f %f",
						 r0.origin.x, r0.origin.y, r0.size.width, r0.size.height,
						 r1.origin.x, r1.origin.y, r1.size.width, r1.size.height];

	[[NSUserDefaults standardUserDefaults] setObject: string forKey: defaultName];
}

@end
