//
//  MGScopeBar.h
//  MGScopeBar
//
//  Created by Matt Gemmell on 15/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import <Cocoa/Cocoa.h>
#import "MGScopeBarDelegateProtocol.h"

@interface MGScopeBar : NSView {
@private
	IBOutlet id <MGScopeBarDelegate, NSObject> delegate; // weak ref.
	NSMutableArray *_separatorPositions; // x-coords of separators, indexed by their group-number.
	NSMutableArray *_groups; // groups of items.
	NSView *_accessoryView; // weak ref since it's a subview.
	NSMutableDictionary *_identifiers; // map of identifiers to items.
	NSMutableArray *_selectedItems; // all selected items in all groups; see note below.
	float _lastWidth; // previous width of view from when we last resized.
	NSInteger _firstCollapsedGroup; // index of first group collapsed into a popup.
	float _totalGroupsWidthForPopups; // total width needed to show all groups expanded (excluding padding and accessory).
	float _totalGroupsWidth; // total width needed to show all groups as native-width popups (excluding padding and accessory).
	BOOL _smartResizeEnabled; // whether to do our clever collapsing/expanding of buttons when resizing (Smart Resizing).
}

@property(assign) id delegate; // should implement the MGScopeBarDelegate protocol.

- (void)reloadData; // causes the scope-bar to reload all groups/items from its delegate.
- (void)sizeToFit; // only resizes vertically to optimum height; does not affect width.
- (void)adjustSubviews; // performs Smart Resizing if enabled. You should only need to call this yourself if you change the width of the accessoryView.

// Smart Resize is the intelligent conversion of button-groups into NSPopUpButtons and vice-versa, based on available space.
// This functionality is enabled (YES) by default. Changing this setting will automatically call -reloadData.
- (BOOL)smartResizeEnabled;
- (void)setSmartResizeEnabled:(BOOL)enabled;

// The following method must be used to manage selections in the scope-bar; do not attempt to manipulate buttons etc directly.
- (void)setSelected:(BOOL)selected forItem:(NSString *)identifier inGroup:(int)groupNumber;
- (NSArray *)selectedItems;

/*
 Note:	The -selectedItems method returns an array of arrays.
		Each index in the returned array represents the group of items at that index.
		The contents of each sub-array are the identifiers of each selected item in that group.
		Sub-arrays may be empty, but will always be present (i.e. you will always find an NSArray).
		Depending on the group's selection-mode, sub-arrays may contain zero, one or many identifiers.
		The identifiers in each sub-array are not in any particular order.
 */

@end
