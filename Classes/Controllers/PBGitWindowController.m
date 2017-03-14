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

	if ([self isWindowLoaded]) {
		// Point window proxy icon at project directory, not internal .git dir
		[[self window] setRepresentedURL:self.repository.workingDirectoryURL];
	}
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


- (void) windowDidLoad
{
	[super windowDidLoad];

	// Explicitly set the frame using the autosave name
	// Opening the first and second documents works fine, but the third and subsequent windows aren't positioned correctly
	[[self window] setFrameUsingName:@"GitX"];
	[[self window] setRepresentedURL:self.repository.workingDirectoryURL];

	sidebarController = [[PBGitSidebarController alloc] initWithRepository:repository superController:self];
	[[sidebarController view] setFrame:[sourceSplitView bounds]];
	[sourceSplitView addSubview:[sidebarController view]];
	[sourceListControlsView addSubview:sidebarController.sourceListControlsView];

	[[statusField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[progressIndicator setUsesThreadedAnimation:YES];
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

	NSMutableArray *nonSubmoduleURLs = [NSMutableArray array];

	for (NSURL *fileURL in fileURLs) {
		GTSubmodule *submodule = [self.repository submoduleAtPath:fileURL.path error:NULL];
		if (!submodule) {
			[nonSubmoduleURLs addObject:fileURL];
		} else {
			NSURL *submoduleURL = [submodule.parentRepository.fileURL URLByAppendingPathComponent:submodule.path isDirectory:YES];
			[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:submoduleURL
																				   display:YES
																		 completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
																			 // Do nothing on completion.
																			 return;
																		 }];
		}
	}

	[[NSWorkspace sharedWorkspace] openURLs:nonSubmoduleURLs
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

	NSError *error = nil;
	BOOL success = [repository beginFetchFromRemoteForRef:ref error:&error windowController:self];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction) fetchAllRemotes:(id)sender {
	NSError *error = nil;
	BOOL success = [repository beginFetchFromRemoteForRef:nil error:&error windowController:self];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (void) pull:(id)sender rebase:(BOOL)rebase {
	PBGitRef *ref = [self selectedItem].revSpecifier.ref;
	PBGitRef *remoteRef = [repository remoteRefForBranch:ref error:NULL];

	NSError *error = nil;
	BOOL success = [repository beginPullFromRemote:remoteRef forRef:ref rebase:rebase error:&error windowController:self];
	if (!success) {
		[self showErrorSheet:error];
	}
}

/* FIXME: It might be possible to merge this with the previous method.
 * It doesn't help that it ignores its rebase parameter, and that it passes nil
 * which ultimately will result in the same thing (use remoteRefForBranch:).
 */
- (void) pullDefault:(id)sender rebase:(BOOL)rebase {
	PBGitRef *ref = [self selectedItem].revSpecifier.ref;

	NSError *error = nil;
	BOOL success = [repository beginPullFromRemote:nil forRef:ref rebase:NO error:&error windowController:self];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction) pullRemote:(id)sender {
	[self pull:sender rebase:NO];
}

- (IBAction) pullRebaseRemote:(id)sender {
	[self pull:sender rebase:YES];
}

- (IBAction) pullDefaultRemote:(id)sender {
	[self pullDefault:sender rebase:NO];
}

- (IBAction) pullRebaseDefaultRemote:(id)sender {
	[self pullDefault:sender rebase:YES];
}

- (PBSourceViewItem *) selectedItem {
	NSOutlineView *sourceView = sidebarController.sourceView;
	return [sourceView itemAtRow:sourceView.selectedRow];
}

- (IBAction) stashSave:(id) sender
{
	NSError *error = nil;
	BOOL success = [repository stashSaveWithKeepIndex:NO error:&error];

	if (!success) [self showErrorSheet:error];
}

- (IBAction) stashSaveWithKeepIndex:(id) sender
{
	NSError *error = nil;
	BOOL success = [repository stashSaveWithKeepIndex:YES error:&error];

	if (!success) [self showErrorSheet:error];
}

- (IBAction) stashPop:(id) sender
{
	if ([repository.stashes count] <= 0) return;

	PBGitStash * latestStash = [repository.stashes objectAtIndex:0];
	NSError *error = nil;
	BOOL success = [repository stashPop:latestStash error:&error];

	if (!success) [self showErrorSheet:error];
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

- (IBAction) openFiles:(id)sender {
	NSArray <NSURL *> *fileURLs = [self selectedURLsFromSender:sender];
	[self openURLs:fileURLs];
}

- (IBAction) revealInFinder:(id)sender
{
	[self revealURLsInFinder:@[self.repository.workingDirectoryURL]];
}

- (IBAction) openInTerminal:(id)sender
{
	[PBTerminalUtil runCommand:@"git status" inDirectory:self.repository.workingDirectoryURL];
}

- (IBAction) refresh:(id)sender
{
	[contentController refresh:self];
}

@end
