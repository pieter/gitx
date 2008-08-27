//
//  PBDetailController.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBDetailController.h"
#import "CWQuickLook.h"
#import "PBGitGrapher.h"

#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")


@implementation PBDetailController

@synthesize repository, selectedTab, webCommit, rawCommit, gitTree;

- (id)initWithRepository:(PBGitRepository*)theRepository;
{
	if(self = [self initWithWindowNibName:@"RepositoryWindow"])
	{
		self.repository = theRepository;
		[self showWindow:nil];
	}
	return self;
}

- (void)awakeFromNib
{
	[fileBrowser setTarget:self];
	[fileBrowser setDoubleAction:@selector(openSelectedFile:)];
	self.selectedTab = [[NSUserDefaults standardUserDefaults] integerForKey:@"Repository Window Selected Tab Index"];;
	[commitController addObserver:self forKeyPath:@"selection" options:(NSKeyValueObservingOptionNew,NSKeyValueObservingOptionOld) context:@"commitChange"];
	[treeController addObserver:self forKeyPath:@"selection" options:0 context:@"treeChange"];
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
		[[self window] makeFirstResponder:searchField];
	else
		[super keyDown: event];
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

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (![[aTableColumn identifier] isEqualToString:@"subject"])
		return;

	if (self.repository.revisionList.grapher) {
		PBGitGrapher* g = self.repository.revisionList.grapher;
		[aCell setCellInfo: [g cellInfoForRow:rowIndex]];
	}
}
@end
