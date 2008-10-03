//
//  PBGitHistoryView.m
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitHistoryController.h"
#import "CWQuickLook.h"
#import "PBGitGrapher.h"
#import "PBGitRevisionCell.h"
#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")


@implementation PBGitHistoryController
@synthesize selectedTab, webCommit, rawCommit, gitTree, commitController;

- (void)awakeFromNib
{
	self.selectedTab = [[NSUserDefaults standardUserDefaults] integerForKey:@"Repository Window Selected Tab Index"];;
	[commitController addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionNew,NSKeyValueObservingOptionOld) context:@"commitChange"];
	[treeController addObserver:self forKeyPath:@"selection" options:0 context:@"treeChange"];
	[repository addObserver:self forKeyPath:@"currentBranch" options:0 context:@"branchChange"];
	NSSize cellSpacing = [commitList intercellSpacing];
	cellSpacing.height = 0;
	[commitList setIntercellSpacing:cellSpacing];
	[fileBrowser setTarget:self];
	[fileBrowser setDoubleAction:@selector(openSelectedFile:)];

	if ([repository.currentBranch count] == 0) {
		[repository reloadRefs];
		[repository readCurrentBranch];
	}
	else
		[repository lazyReload];

	// Set a sort descriptor for the subject column in the history list, as
	// It can't be sorted by default (because it's bound to a PBGitCommit)
	[[commitList tableColumnWithIdentifier:@"subject"] setSortDescriptorPrototype:[[NSSortDescriptor alloc] initWithKey:@"subject" ascending:YES]];
	
	[super awakeFromNib];
	// We bind this ourselves because otherwise we would lose our selection
	[branchesController bind:@"selectionIndexes" toObject:repository withKeyPath:@"currentBranch" options:nil];
}

- (void) updateKeys
{
	NSArray* selection = [commitController selectedObjects];
	
	// Remove any references in the QLPanel
	//[[QLPreviewPanel sharedPreviewPanel] setURLs:[NSArray array] currentIndex:0 preservingDisplayState:YES];
	// We have to do this manually, as NSTreeController leaks memory?
	//[treeController setSelectionIndexPaths:[NSArray array]];
	
	if ([selection count] > 0)
		realCommit = [selection objectAtIndex:0];
	else
		realCommit = nil;
	
	self.webCommit = nil;
	self.rawCommit = nil;
	self.gitTree = nil;
	
	switch (self.selectedTab) {
		case 0:	self.webCommit = realCommit;			break;
		case 1:	self.rawCommit = realCommit;			break;
		case 2:	self.gitTree   = realCommit.tree;	break;
	}
}	


- (void) setSelectedTab: (int) number
{
	selectedTab = number;
	[[NSUserDefaults standardUserDefaults] setInteger:selectedTab forKey:@"Repository Window Selected Tab Index"];
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
	else if([(NSString *)context isEqualToString:@"branchChange"]) {
		// Reset the sorting
		commitController.sortDescriptors = [NSArray array];
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
	self.selectedTab = 0;
}
- (IBAction) setRawView: sender {
	self.selectedTab = 1;
}
- (IBAction) setTreeView: sender {
	self.selectedTab = 2;
}

- (void)keyDown:(NSEvent*)event
{
	if ([[event charactersIgnoringModifiers] isEqualToString: @"f"] && [event modifierFlags] & NSAlternateKeyMask && [event modifierFlags] & NSCommandKeyMask)
		[superController.window makeFirstResponder: searchField];
	else
		[super keyDown: event];
}

- (void) copyCommitInfo
{
	PBGitCommit *commit = [[commitController selectedObjects] objectAtIndex:0];
	if (!commit)
		return;
	NSString *info = [NSString stringWithFormat:@"%@ (%@)", [commit sha], [commit subject]];

	NSPasteboard *a =[NSPasteboard generalPasteboard];
	[a declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[a setString:info forType: NSStringPboardType];
	
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

- (IBAction) refresh: sender
{
	[repository reloadRefs];
	[repository.revisionList reload];
}

- (void) selectCommit: (NSString*) commit
{
	NSPredicate* selection = [NSPredicate predicateWithFormat:@"sha == %@", commit];
	NSArray* selectedCommits = [repository.revisionList.commits filteredArrayUsingPredicate:selection];
	[commitController setSelectedObjects: selectedCommits];
	int index = [[commitController selectionIndexes] firstIndex];
	[commitList scrollRowToVisible: index];
}

- (BOOL) hasNonlinearPath
{
	return [commitController filterPredicate] || [[commitController sortDescriptors] count] > 0;
}

- (void) removeView
{
	[webView close];
	[super removeView];
}
@end
