//
//  PBWebChangesController.m
//  GitX
//
//  Created by Pieter de Bie on 22-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBWebChangesController.h"

@implementation PBWebChangesController

- (void) awakeFromNib
{
	startFile = @"diff";
	[super awakeFromNib];

	[unstagedFilesController addObserver:self forKeyPath:@"selection" options:0 context:@"UnstagedFileSelected"];
	[cachedFilesController addObserver:self forKeyPath:@"selection" options:0 context:@"cachedFileSelected"];
}

static PBChangedFile *lastFileSelected = nil;

- (void) didLoad
{
	if (lastFileSelected)
		[self showDiff: lastFileSelected];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if ([[object selectedObjects] count] == 0)
		return;

	if (object == unstagedFilesController)
		[cachedFilesController setSelectionIndexes:[NSIndexSet indexSet]];
	else
		[unstagedFilesController setSelectionIndexes:[NSIndexSet indexSet]];

	PBChangedFile *file = [[object selectedObjects] objectAtIndex:0];

	[self showDiff: file];
}

- (void) showDiff:(PBChangedFile *)file
{
	if (!finishedLoading) {
		lastFileSelected = file;
		return;
	}

	// Don't reload if we already display this file
	if (previousFile == file)
		return;

	previousFile = file;

	id script = [view windowScriptObject];
	[script callWebScriptMethod:@"showFileChanges" withArguments:[NSArray arrayWithObject:file]];	
}
@end
