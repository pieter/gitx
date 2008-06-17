//
//  PBDetailController.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBDetailController.h"
#import "CWQuickLook.h"

#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")


@implementation PBDetailController

@synthesize selectedTab, webCommit, rawCommit, gitTree;

- awakeFromNib
{
	[fileBrowser setTarget:self];
	[fileBrowser setDoubleAction:@selector(openSelectedFile:)];
	self.selectedTab = [NSNumber numberWithInt:0];
	[commitController addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionNew,NSKeyValueObservingOptionOld) context:@"commitChange"];
	[treeController addObserver:self forKeyPath:@"selection" options:0 context:@"treeChange"];
	return self;
}

- (void) updateKeys
{
	NSArray* selection = [commitController selectedObjects];

	// Remove any references in the QLPanel
	[[QLPreviewPanel sharedPreviewPanel] setURLs:[NSArray array] currentIndex:0 preservingDisplayState:YES];
	// We have to do this manually, as NSTreeController leaks memory?
	[treeController setSelectionIndexPaths:[NSArray array]];

	if ([selection count] > 0)
		realCommit = [selection objectAtIndex:0];
	else
		realCommit = nil;
	
	self.webCommit = nil;
	self.rawCommit = nil;
	self.gitTree = nil;
	

	int num = [self.selectedTab intValue];

	if (num == 0) // Detailed view
		self.webCommit = realCommit;
	else if (num == 1)
		self.rawCommit = realCommit;
	else if (num == 2)
		self.gitTree = realCommit.tree;
}	


- (void) setSelectedTab: (NSNumber*) number
{
	selectedTab = number;
	[self updateKeys];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(NSString *)context isEqualToString: @"commitChange"]) {
		[self updateKeys];
		return;
	}
	else if ([(NSString *)context isEqualToString: @"treeChange"]) {
			[self updateQuicklookForce: NO];
	}

	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (IBAction) openSelectedFile: sender
{
	NSArray* selectedFiles = [treeController selectedObjects];
	if ([selectedFiles count] == 0)
		return;
	PBGitTree* tree = [selectedFiles objectAtIndex:0];
	NSString* name = [tree tmpFileNameForContents];
	[[NSWorkspace sharedWorkspace] openTempFile:name];
}

- (IBAction) setDetailedView: sender {
	self.selectedTab = [NSNumber numberWithInt:0];
}
- (IBAction) setRawView: sender {
	self.selectedTab = [NSNumber numberWithInt:1];
}
- (IBAction) setTreeView: sender {
	self.selectedTab = [NSNumber numberWithInt:2];
}

- (IBAction) toggleQuickView: sender
{
	id panel = [QLPreviewPanel sharedPreviewPanel];
	if ([panel isOpen]) {
		[panel closePanel];
	} else {
		[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:1];
		[self updateQuicklookForce: YES];
	}
}

- (void) updateQuicklookForce: (BOOL) force
{
	if (!force && ![[QLPreviewPanel sharedPreviewPanel] isOpen])
		return;
	
	NSArray* selectedFiles = [treeController selectedObjects];

	if ([selectedFiles count] == 0)
		return;
	
	NSMutableArray* fileNames = [NSMutableArray array];
	for (PBGitTree* tree in selectedFiles) {
		NSString* s = [tree tmpFileNameForContents];
		if (s)
			[fileNames addObject:[NSURL fileURLWithPath: s]];
	}

	[[QLPreviewPanel sharedPreviewPanel] setURLs:fileNames currentIndex:0 preservingDisplayState:YES];

}

@end
