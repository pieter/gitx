//
//  PBSourceViewItem.h
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PBGitRevSpecifier;

@interface PBSourceViewItem : NSObject {
	NSMutableArray *children;

	NSString *title;
	PBGitRevSpecifier *revSpecifier;

	BOOL isGroupItem;
}

+ (PBSourceViewItem *)groupItemWithTitle:(NSString *)title;
+ (PBSourceViewItem *)itemWithRevSpec:(PBGitRevSpecifier *)revSpecifier;

- (void)addChild:(PBSourceViewItem *)child;

@property(retain) NSString *title;
@property(readonly) NSMutableArray *children;
@property(assign) BOOL isGroupItem;
@property(retain) PBGitRevSpecifier *revSpecifier;

@end
