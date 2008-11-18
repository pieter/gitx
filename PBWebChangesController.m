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
	selectedFile = nil;
	selectedFileIsCached = NO;

	startFile = @"commit";
	[super awakeFromNib];

	[unstagedFilesController addObserver:self forKeyPath:@"selection" options:0 context:@"UnstagedFileSelected"];
	[cachedFilesController addObserver:self forKeyPath:@"selection" options:0 context:@"cachedFileSelected"];
}

- (void) didLoad
{
	[self refresh];
}

- (BOOL) amend
{
	return controller.amend;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	int count = [[object selectedObjects] count];
	if (count == 0)
		return;

	// TODO: Move this to commitcontroller
	if (object == unstagedFilesController)
		[cachedFilesController setSelectionIndexes:[NSIndexSet indexSet]];
	else
		[unstagedFilesController setSelectionIndexes:[NSIndexSet indexSet]];

	if (count > 1) {
		[self showMultiple: [object selectedObjects]];
		return;
	}

	selectedFile = [[object selectedObjects] objectAtIndex:0];
	selectedFileIsCached = object == cachedFilesController;

	[self refresh];
}

- (void) showMultiple: (NSArray *)objects
{
	[[self script] callWebScriptMethod:@"showMultipleFilesSelection" withArguments:[NSArray arrayWithObject:objects]];
}

- (void) refresh
{
	if (!finishedLoading || !selectedFile)
		return;

	id script = [view windowScriptObject];
	[script callWebScriptMethod:@"showFileChanges"
				  withArguments:[NSArray arrayWithObjects:selectedFile, [NSNumber numberWithBool:selectedFileIsCached], nil]];
}

- (void) stageHunk:(NSString *)hunk reverse:(BOOL)reverse
{
	[controller stageHunk: hunk reverse:reverse];
	[self refresh];
}

- (void) setStateMessage:(NSString *)state
{
	id script = [view windowScriptObject];
	[script callWebScriptMethod:@"setState" withArguments: [NSArray arrayWithObject:state]];
}

@end
