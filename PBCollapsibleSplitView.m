//
//  PBCollapsibleSplitView.m
//  GitX
//
//  Created by Johannes Gilger on 6/21/09.
//  Copyright 2009 Johannes Gilger. All rights reserved.
//

#import "PBCollapsibleSplitView.h"

@implementation PBCollapsibleSplitView
@synthesize topViewMin, bottomViewMin;

- (void)setTopMin:(CGFloat)topMin andBottomMin:(CGFloat)bottomMin {
	topViewMin = topMin;
	bottomViewMin = bottomMin;
}

- (void)uncollapse {
	for (NSView *subview in [self subviews]) {
		if([self isSubviewCollapsed:subview]) {
			[self setPosition:[self frame].size.height / 3 ofDividerAtIndex:0];
			[self adjustSubviews];
		}
	}
}

@end
