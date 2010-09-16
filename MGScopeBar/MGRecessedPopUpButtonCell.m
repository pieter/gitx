//
//  MGRecessedPopUpButtonCell.m
//  MGScopeBar
//
//  Created by Matt Gemmell on 20/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGRecessedPopUpButtonCell.h"


@implementation MGRecessedPopUpButtonCell


- (id)initTextCell:(NSString *)title pullsDown:(BOOL)pullsDown
{
	if ((self = [super initTextCell:title pullsDown:pullsDown])) {
		recessedButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 30, 20)]; // arbitrary frame.
		[recessedButton setTitle:@""];
		[recessedButton setBezelStyle:NSRecessedBezelStyle];
		[recessedButton setButtonType:NSPushOnPushOffButton];
		[[recessedButton cell] setHighlightsBy:NSCellIsBordered | NSCellIsInsetButton];
		[recessedButton setShowsBorderOnlyWhileMouseInside:NO];
		[recessedButton setState:NSOnState]; // ensures it looks pushed-in.
	}
	return self;
}


- (void)dealloc
{
	[recessedButton release];
	[super dealloc];
}


- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// Inset title rect since its position is broken when NSPopUpButton
	// isn't using its selected item as its title.
	NSRect titleFrame = cellFrame;
	titleFrame.origin.y += 1.0;
	[super drawTitleWithFrame:titleFrame inView:controlView];
}


- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	[recessedButton setFrame:frame];
	[recessedButton drawRect:frame];
}


@end
