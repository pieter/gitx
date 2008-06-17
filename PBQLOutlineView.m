//
//  PBQLOutlineView.m
//  GitX
//
//  Created by Pieter de Bie on 6/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBQLOutlineView.h"


@implementation PBQLOutlineView

- (void) keyDown: (NSEvent *) event
{
	if ([[event characters] isEqualToString:@" "]) {
		[controller toggleQuickView:self];
		return;
	}

	[super keyDown:event];
}
@end
