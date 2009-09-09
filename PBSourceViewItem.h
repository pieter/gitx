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
	PBSourceViewItem *parent;

	BOOL isGroupItem;
}

+ (PBSourceViewItem *)groupItemWithTitle:(NSString *)title;
+ (PBSourceViewItem *)itemWithRevSpec:(PBGitRevSpecifier *)revSpecifier;
+ (PBSourceViewItem *)itemWithTitle:(NSString *)title;

- (void)addChild:(PBSourceViewItem *)child;

// This adds the ref to the path, which should match the item's title,
// so "refs/heads/pu/pb/sidebar" would have the path [@"pu", @"pb", @"sidebare"]
// to the 'local' branch thing
- (void)addRev:(PBGitRevSpecifier *)revSpecifier toPath:(NSArray *)path;
- (PBSourceViewItem *)findRev:(PBGitRevSpecifier *)rev;

- (NSImage *)icon;

@property(retain) NSString *title;
@property(readonly) NSMutableArray *children;
@property(assign) BOOL isGroupItem;
@property(retain) PBGitRevSpecifier *revSpecifier;
@property(retain) PBSourceViewItem *parent;
@end
