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
		[self showDiff: lastFileSelected cached:NO];
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
	if ([[object selectedObjects] count] == 0)
		return;

	// TODO: Move this to commitcontroller
	if (object == unstagedFilesController)
		[cachedFilesController setSelectionIndexes:[NSIndexSet indexSet]];
	else
		[unstagedFilesController setSelectionIndexes:[NSIndexSet indexSet]];

	PBChangedFile *file = [[object selectedObjects] objectAtIndex:0];

	[self showDiff: file cached: object == cachedFilesController];
}

- (void) showDiff:(PBChangedFile *)file cached:(BOOL) cached
{
	if (!finishedLoading) {
		lastFileSelected = file;
		return;
	}

	id script = [view windowScriptObject];
	NSLog(@"Showing diff..");
	[script callWebScriptMethod:@"showFileChanges" withArguments:[NSArray arrayWithObjects:file, [NSNumber numberWithBool:cached], nil]];
}
@end
