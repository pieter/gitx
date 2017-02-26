//
//  PBFileChangesTableView.m
//  GitX
//
//  Created by Pieter de Bie on 09-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBFileChangesTableView.h"
#import "PBGitCommitController.h"

@interface PBFileChangesTableView ()
- (PBGitCommitController *) delegate;
@end


@implementation PBFileChangesTableView

#pragma mark NSTableView overrides

- (PBGitCommitController *) delegate
{
	return (PBGitCommitController *)[super delegate];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	if ([self delegate]) {
		NSPoint eventLocation = [self convertPoint:[theEvent locationInWindow] fromView: nil];
		NSInteger rowIndex = [self rowAtPoint:eventLocation];
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:YES];
		return [super menuForEvent:theEvent];
	}

	return nil;
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
	return NSDragOperationEvery;
}

#pragma mark NSView overrides

-(BOOL)acceptsFirstResponder
{
    return [self numberOfRows] > 0;
}

-(NSView *)nextKeyView
{
    return [[self delegate] nextKeyViewFor:self];
}

-(NSView *)previousKeyView
{
    return [[self delegate] previousKeyViewFor:self];
}

@end
