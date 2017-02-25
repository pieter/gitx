//
//  PBDetailController.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitWindowController.h"
#import "PBGitHistoryController.h"
#import "PBGitCommitController.h"
#import "PBTerminalUtil.h"
#import "PBCommitHookFailedSheet.h"
#import "PBGitXMessageSheet.h"
#import "PBGitSidebarController.h"
#import "RJModalRepoSheet.h"
#import "PBAddRemoteSheet.h"
#import "PBSourceViewItem.h"
#import "PBGitRevSpecifier.h"
#import "PBGitRef.h"
#import "PBError.h"
#import "PBRepositoryDocumentController.h"

@interface PBGitWindowController ()

@property (nonatomic, strong) RJModalRepoSheet* currentModalSheet;

@end

@implementation PBGitWindowController

@synthesize repository;
@synthesize currentModalSheet;

- (id)initWithRepository:(PBGitRepository*)theRepository displayDefault:(BOOL)displayDefault
{
	if (!(self = [self initWithWindowNibName:@"RepositoryWindow"]))
		return nil;

	self.repository = theRepository;

	return self;
}

- (void)synchronizeWindowTitleWithDocumentName
{
    [super synchronizeWindowTitleWithDocumentName];

    // Point window proxy icon at project directory, not internal .git dir
    [[self window] setRepresentedURL:self.repository.workingDirectoryURL];
}

- (void)windowWillClose:(NSNotification *)notification
{
//	NSLog(@"Window will close!");

	if (sidebarController)
		[sidebarController closeView];

	if (contentController)
		[contentController removeObserver:self forKeyPath:@"status"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(showCommitView:)) {
		[menuItem setState:(contentController == sidebarController.commitViewController) ? YES : NO];
		return ![repository isBareRepository];
	} else if ([menuItem action] == @selector(showHistoryView:)) {
		[menuItem setState:(contentController != sidebarController.commitViewController) ? YES : NO];
		return ![repository isBareRepository];
	} else if (menuItem.action == @selector(fetchRemote:)) {
		return [self validateMenuItem:menuItem remoteTitle:@"Fetch “%@”" plainTitle:@"Fetch"];
	} else if (menuItem.action == @selector(pullRemote:)) {
		return [self validateMenuItem:menuItem remoteTitle:@"Pull From “%@”" plainTitle:@"Pull"];
	} else if (menuItem.action == @selector(pullRebaseRemote:)) {
		return [self validateMenuItem:menuItem remoteTitle:@"Pull From “%@” and Rebase" plainTitle:@"Pull and Rebase"];
	}
	
	return YES;
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem remoteTitle:(NSString *)localisationKeyWithRemote plainTitle:(NSString *)localizationKeyWithoutRemote
{
	PBSourceViewItem *item = [self selectedItem];
	PBGitRef *ref = item.ref;

	if (!ref && (item.parent == sidebarController.remotes)) {
		ref = [PBGitRef refFromString:[kGitXRemoteRefPrefix stringByAppendingString:item.title]];
	}
	
	if (ref.isRemote) {
		menuItem.title = [NSString stringWithFormat:NSLocalizedString(localisationKeyWithRemote, @""), ref.remoteName];
		return YES;
	}

	menuItem.title = NSLocalizedString(localizationKeyWithoutRemote, @"");
	return NO;
}


- (void) awakeFromNib
{
	[[self window] setDelegate:self];
	[[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[[self window] setContentBorderThickness:31.0f forEdge:NSMinYEdge];

	sidebarController = [[PBGitSidebarController alloc] initWithRepository:repository superController:self];
	[[sidebarController view] setFrame:[sourceSplitView bounds]];
	[sourceSplitView addSubview:[sidebarController view]];
	[sourceListControlsView addSubview:sidebarController.sourceListControlsView];

	[[statusField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[progressIndicator setUsesThreadedAnimation:YES];

	[self showWindow:nil];
}

- (void) removeAllContentSubViews
{
	if ([contentSplitView subviews])
		while ([[contentSplitView subviews] count] > 0)
			[[[contentSplitView subviews] lastObject] removeFromSuperviewWithoutNeedingDisplay];
}

- (void) changeContentController:(PBViewController *)controller
{
	if (!controller || (contentController == controller))
		return;

	if (contentController)
		[contentController removeObserver:self forKeyPath:@"status"];

	[self removeAllContentSubViews];

	contentController = controller;
	
	[[contentController view] setFrame:[contentSplitView bounds]];
	[contentSplitView addSubview:[contentController view]];

//	[self setNextResponder: contentController];
	[[self window] makeFirstResponder:[contentController firstResponder]];
	[contentController updateView];
	[contentController addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:@"statusChange"];
}

- (void) showCommitView:(id)sender
{
	[sidebarController selectStage];
}

- (void) showHistoryView:(id)sender
{
	[sidebarController selectCurrentBranch];
}

- (void)showCommitHookFailedSheet:(NSString *)messageText infoText:(NSString *)infoText commitController:(PBGitCommitController *)controller
{
	[PBCommitHookFailedSheet beginWithMessageText:messageText
										 infoText:infoText
								 commitController:controller];
}

- (void)showMessageSheet:(NSString *)messageText infoText:(NSString *)infoText
{
	[PBGitXMessageSheet beginSheetWithMessage:messageText info:infoText windowController:self];
}

- (void)showErrorSheet:(NSError *)error
{
	if ([[error domain] isEqualToString:PBGitXErrorDomain])
	{
		[PBGitXMessageSheet beginSheetWithError:error windowController:self];
	}
	else
	{
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window]
												   modalDelegate:self
												  didEndSelector:nil
													 contextInfo:nil];
	}
}

- (void)showErrorSheetTitle:(NSString *)title message:(NSString *)message arguments:(NSArray *)arguments output:(NSString *)output
{
	NSString *command = [arguments componentsJoinedByString:@" "];
	NSString *reason = [NSString stringWithFormat:@"%@\n\ncommand: git %@\n%@", message, command, output];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  title, NSLocalizedDescriptionKey,
							  reason, NSLocalizedRecoverySuggestionErrorKey,
							  nil];
	NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:0 userInfo:userInfo];
	[self showErrorSheet:error];
}

- (IBAction) revealInFinder:(id)sender
{
	[[PBRepositoryDocumentController sharedDocumentController] revealURLsInFinder:@[self.repository.workingDirectoryURL]];
}

- (IBAction) openInTerminal:(id)sender
{
	[PBTerminalUtil runCommand:@"git status" inDirectory:self.repository.workingDirectoryURL];
}

- (IBAction) refresh:(id)sender
{
	[contentController refresh:self];
}

- (void) updateStatus
{
	NSString *status = contentController.status;
	BOOL isBusy = contentController.isBusy;

	if (!status) {
		status = @"";
		isBusy = NO;
	}

	[statusField setStringValue:status];

	if (isBusy) {
		[progressIndicator startAnimation:self];
		[progressIndicator setHidden:NO];
	}
	else {
		[progressIndicator stopAnimation:self];
		[progressIndicator setHidden:YES];
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(__bridge NSString *)context isEqualToString:@"statusChange"]) {
		[self updateStatus];
		return;
	}

	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setHistorySearch:(NSString *)searchString mode:(PBHistorySearchMode)mode
{
	[sidebarController setHistorySearch:searchString mode:mode];
}

- (void)showModalSheet:(RJModalRepoSheet *)sheet
{
	if (self.currentModalSheet == nil) {
		[NSApp beginSheet:[sheet window]
		   modalForWindow:self.window
			modalDelegate:sheet
		   didEndSelector:nil
			  contextInfo:NULL];
		self.currentModalSheet = sheet;
	}
}

- (void)hideModalSheet:(RJModalRepoSheet *)sheet
{
	if (self.currentModalSheet == sheet) {
		[NSApp endSheet:sheet.window];
		[sheet.window orderOut:sheet];
		self.currentModalSheet = nil;
	} else {
		assert(self.currentModalSheet == sheet);
	}
}


- (void)openURLs:(NSArray <NSURL *> *)fileURLs
{
	if (fileURLs.count == 0) return;

	[[NSWorkspace sharedWorkspace] openURLs:fileURLs
					withAppBundleIdentifier:nil
									options:0
			 additionalEventParamDescriptor:nil
						  launchIdentifiers:NULL];
}

- (void)revealURLsInFinder:(NSArray <NSURL *> *)fileURLs
{
	if (fileURLs.count == 0) return;

	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

#pragma mark IBActions

- (IBAction) showAddRemoteSheet:(id)sender
{
	[[[PBAddRemoteSheet alloc] initWithWindowController:self] show];
}


- (IBAction) fetchRemote:(id)sender {
	PBGitRef *ref = [self selectedItem].ref;
	[repository beginFetchFromRemoteForRef:ref];
}

- (IBAction) fetchAllRemotes:(id)sender {
	[repository beginFetchFromRemoteForRef:nil];
}

- (IBAction) pullRemote:(id)sender {
	[self pull:sender rebase:NO];
}

- (IBAction) pullRebaseRemote:(id)sender {
	[self pull:sender rebase:YES];
}

- (void) pull:(id)sender rebase:(BOOL)rebase {
	PBGitRef *ref = [self selectedItem].revSpecifier.ref;
	PBGitRef *remoteRef = [repository remoteRefForBranch:ref error:NULL];
	[repository beginPullFromRemote:remoteRef forRef:ref rebase:rebase];
}

- (IBAction) pullDefaultRemote:(id)sender {
	[self pullDefault:sender rebase:NO];
}

- (IBAction) pullRebaseDefaultRemote:(id)sender {
	[self pullDefault:sender rebase:YES];
}

- (void) pullDefault:(id)sender rebase:(BOOL)rebase {
	PBGitRef *ref = [self selectedItem].revSpecifier.ref;
	[repository beginPullFromRemote:nil forRef:ref rebase:NO];
}

- (PBSourceViewItem *) selectedItem {
	NSOutlineView *sourceView = sidebarController.sourceView;
	return [sourceView itemAtRow:sourceView.selectedRow];
}

- (IBAction) stashSave:(id) sender
{
    [repository stashSaveWithKeepIndex:NO];
}

- (IBAction) stashSaveWithKeepIndex:(id) sender
{
    [repository stashSaveWithKeepIndex:YES];
}

- (IBAction) stashPop:(id) sender
{
    if ([repository.stashes count] > 0) {
        PBGitStash * latestStash = [repository.stashes objectAtIndex:0];
        [repository stashPop:latestStash];
    }
}


- (NSArray <NSURL *> *)selectedURLsFromSender:(id)sender {
	NSArray *selectedFiles = [sender representedObject];
	if (![selectedFiles isKindOfClass:[NSArray class]] || [selectedFiles count] == 0)
		return nil;

	NSMutableArray *URLs = [NSMutableArray array];
	for (id file in selectedFiles) {
		NSString *path = file;
		// Those can be PBChangedFiles sent by PBGitIndexController. Get their path.
		if ([file respondsToSelector:@selector(path)]) {
			path = [file path];
		}

		if (![path isKindOfClass:[NSString class]])
			continue;
		[URLs addObject:[self.repository.workingDirectoryURL URLByAppendingPathComponent:path]];
	}

	return URLs;
}

- (IBAction)openFilesAction:(id)sender
{
	NSArray *URLs = [self selectedURLsFromSender:sender];

	[self openURLs:URLs];
}

- (IBAction)showInFinderAction:(id)sender
{
	NSArray *URLs = [self selectedURLsFromSender:sender];
	if ([URLs count] == 0)
		return;

	[self revealURLsInFinder:URLs];
}

#pragma mark -
#pragma mark SplitView Delegates

#define kGitSplitViewMinWidth 150.0f
#define kGitSplitViewMaxWidth 300.0f

#pragma mark min/max widths while moving the divider

- (CGFloat)splitView:(NSSplitView *)view constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	if (proposedMin < kGitSplitViewMinWidth)
		return kGitSplitViewMinWidth;

	return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)view constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if (dividerIndex == 0)
		return kGitSplitViewMaxWidth;

	return proposedMax;
}

#pragma mark constrain sidebar width while resizing the window

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [sender frame];

	CGFloat dividerThickness = [sender dividerThickness];

	NSView *sourceView = [[sender subviews] objectAtIndex:0];
	NSRect sourceFrame = [sourceView frame];
	sourceFrame.size.height = newFrame.size.height;

	NSView *mainView = [[sender subviews] objectAtIndex:1];
	NSRect mainFrame = [mainView frame];
	mainFrame.origin.x = sourceFrame.size.width + dividerThickness;
	mainFrame.size.width = newFrame.size.width - mainFrame.origin.x;
	mainFrame.size.height = newFrame.size.height;

	[sourceView setFrame:sourceFrame];
	[mainView setFrame:mainFrame];
}

@end
