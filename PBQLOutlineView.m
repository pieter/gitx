//
//  PBQLOutlineView.m
//  GitX
//
//  Created by Pieter de Bie on 6/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBQLOutlineView.h"


@implementation PBQLOutlineView

- initWithCoder: (NSCoder *) coder
{
	id a = [super initWithCoder:coder];
	[a setDataSource: a];
	[a registerForDraggedTypes: [NSArray arrayWithObject:NSFilesPromisePboardType]];
	return a;
}

/* Needed to drag outside application */
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL) local
{
	return NSDragOperationCopy;
}

- (void) keyDown: (NSEvent *) event
{
	if ([[event characters] isEqualToString:@" "]) {
		[controller toggleQuickView:self];
		return;
	}

	[super keyDown:event];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *) pb
{
	NSMutableArray* fileNames = [NSMutableArray array];
	for (id tree in items)
		[fileNames addObject: [[[tree representedObject] path] pathExtension]];

	[pb declareTypes:[NSArray arrayWithObject:NSFilesPromisePboardType] owner:self];
    [pb setPropertyList:fileNames forType:NSFilesPromisePboardType];

	return YES;
}

- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	NSMutableArray* fileNames = [NSMutableArray array];
	for (id obj in items) {
		PBGitTree* tree = [obj representedObject];
		[fileNames addObject: [tree path]];
		[tree saveToFolder:[dropDestination path]];
	}
	return fileNames;
}

/* Implemented to satisfy datasourcee protocol */
- (BOOL) outlineView: (NSOutlineView *)ov
         isItemExpandable: (id)item { return NO; }

- (NSInteger)  outlineView: (NSOutlineView *)ov
         numberOfChildrenOfItem:(id)item { return 0; }

- (id)   outlineView: (NSOutlineView *)ov
         child:(NSInteger)index
         ofItem:(id)item { return nil; }

- (id)   outlineView: (NSOutlineView *)ov
         objectValueForTableColumn:(NSTableColumn*)col
         byItem:(id)item { return nil; }
@end
