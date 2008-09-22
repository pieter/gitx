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
	NSString* file = [[NSBundle mainBundle] pathForResource:@"diff" ofType:@"html"];
	NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:file]];
	[[view mainFrame] loadRequest:request];	

	[unstagedFilesController addObserver:self forKeyPath:@"selection" options:0 context:@"UnstagedFileSelected"];
	[cachedFilesController addObserver:self forKeyPath:@"selection" options:0 context:@"cachedFileSelected"];
}

static PBChangedFile *lastFileSelected = nil;

- (void) webView:(id) v didFinishLoadForFrame:(id) frame
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

	if ([view isLoading]) {
		lastFileSelected = file;
		return;
	}
	[self showDiff: file];
}

- (void) showDiff:(PBChangedFile *)file
{
	id script = [view windowScriptObject];
	NSString *changes = [file changes];
	[script callWebScriptMethod:@"showDiff" withArguments:[NSArray arrayWithObject:changes]];	
}
@end
