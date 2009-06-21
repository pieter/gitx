//
//  PBCollapsibleSplitView.h
//  GitX
//
//  Created by Johannes Gilger on 6/21/09.
//  Copyright 2009 Johannes Gilger. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBNiceSplitView.h"

@interface PBCollapsibleSplitView : PBNiceSplitView {
	CGFloat topViewMin;
	CGFloat bottomViewMin;
}

@property (readonly) CGFloat topViewMin;
@property (readonly) CGFloat bottomViewMin;

- (void)setTopMin:(CGFloat)topMin andBottomMin:(CGFloat)bottomMin;
- (void)uncollapse;

@end
