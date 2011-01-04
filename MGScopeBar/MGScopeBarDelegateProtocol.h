//
//  MGScopeBarDelegateProtocol.h
//  MGScopeBar
//
//  Created by Matt Gemmell on 15/03/2008.
//  Copyright 2008 Instinctive Code.
//

#import <Cocoa/Cocoa.h>


// Selection modes for the buttons within a group.
typedef enum _MGScopeBarGroupSelectionMode {
    MGRadioSelectionMode         = 0,	// Exactly one item in the group will be selected at a time (no more, and no less).
    MGMultipleSelectionMode      = 1	// Any number of items in the group (including none) may be selected at a time.
} MGScopeBarGroupSelectionMode;


@class MGScopeBar;
@protocol MGScopeBarDelegate


// Methods used to configure the scope bar.
// Note: all groupNumber parameters are zero-based.

@required
- (int)numberOfGroupsInScopeBar:(MGScopeBar *)theScopeBar;
- (NSArray *)scopeBar:(MGScopeBar *)theScopeBar itemIdentifiersForGroup:(int)groupNumber;
- (NSString *)scopeBar:(MGScopeBar *)theScopeBar labelForGroup:(int)groupNumber; // return nil or an empty string for no label.
- (MGScopeBarGroupSelectionMode)scopeBar:(MGScopeBar *)theScopeBar selectionModeForGroup:(int)groupNumber;
- (NSString *)scopeBar:(MGScopeBar *)theScopeBar titleOfItem:(NSString *)identifier inGroup:(int)groupNumber;

@optional
// If the following method is not implemented, all groups except the first will have a separator before them.
- (BOOL)scopeBar:(MGScopeBar *)theScopeBar showSeparatorBeforeGroup:(int)groupNumber;
- (NSImage *)scopeBar:(MGScopeBar *)theScopeBar imageForItem:(NSString *)identifier inGroup:(int)groupNumber; // default is no image. Will be shown at 16x16.
- (NSView *)accessoryViewForScopeBar:(MGScopeBar *)theScopeBar; // default is no accessory view.


// Notification methods.

@optional
- (void)scopeBar:(MGScopeBar *)theScopeBar selectedStateChanged:(BOOL)selected forItem:(NSString *)identifier inGroup:(int)groupNumber;


@end
