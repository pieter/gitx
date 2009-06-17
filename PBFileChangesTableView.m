//
//  PBFileChangesTableView.m
//  GitX
//
//  Created by Pieter de Bie on 09-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBFileChangesTableView.h"
#import "PBGitIndexController.h"

@implementation PBFileChangesTableView

static const NSUInteger mouseMask = (NSLeftMouseDownMask | NSLeftMouseUpMask | NSRightMouseDownMask | NSRightMouseUpMask | NSOtherMouseDownMask | NSOtherMouseUpMask);

- (BOOL)becomeFirstResponder;
{
    if (![super becomeFirstResponder])
	return NO;
    
	NSUInteger numberOfSelectedRows = [self numberOfSelectedRows];
	NSUInteger numberOfRows = [self numberOfRows];
	
    if ((NSEventMaskFromType([[NSApp currentEvent] type]) & ~mouseMask) &&
		([self numberOfSelectedRows] == 0 && [self numberOfRows] > 0)) {
	if (lastSelectedRowIndexes != nil && numberOfRows == lastRowCount)
	    [self selectRowIndexes:lastSelectedRowIndexes byExtendingSelection:NO];
	else
	    [self selectRow:0 byExtendingSelection:NO];
    }

    [moveButton setKeyEquivalent:@"\r"];
	if (numberOfSelectedRows > 0)
		[moveButton setEnabled:YES];

    return YES;
}

- (BOOL)resignFirstResponder;
{
    if (![super resignFirstResponder])
	return NO;

    lastSelectedRowIndexes = [self selectedRowIndexes];
    lastRowCount = [self numberOfRows];
    
    [moveButton setKeyEquivalent:@""];
	[moveButton setEnabled:NO];

    return YES;
}

- (NSButton *)moveButton;
{
	return moveButton;
}

#pragma mark NSTableView overrides
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	if ([self delegate]) {
		NSPoint eventLocation = [self convertPoint: [theEvent locationInWindow] fromView: nil];
		NSInteger rowIndex = [self rowAtPoint:eventLocation];
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:TRUE];
		return [[self delegate] menuForTable: self];
	}

	return nil;
}

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL) local
{
	return NSDragOperationEvery;
}

@end
