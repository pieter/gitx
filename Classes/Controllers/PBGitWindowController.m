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
#import "PBAddRemoteSheet.h"
#import "PBCreateBranchSheet.h"
#import "PBCreateTagSheet.h"
#import "PBGitDefaults.h"
#import "PBSourceViewItem.h"
#import "PBGitRevSpecifier.h"
#import "PBGitRef.h"
#import "PBError.h"
#import "PBRepositoryDocumentController.h"
#import "PBGitRepositoryDocument.h"
#import "PBRemoteProgressSheet.h"
#import "PBDiffWindowController.h"
#import "PBGitStash.h"
#import "PBGitCommit.h"

@implementation PBGitWindowController

@dynamic document;

- (instancetype)init
{
	self = [super initWithWindowNibName:@"RepositoryWindow"];
	if (!self)
		return nil;

	return self;
}

- (PBGitRepository *)repository
{
	return [self.document repository];
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

	[self.historyViewController closeView];
	[self.commitViewController closeView];

	if (contentController)
		[contentController removeObserver:self forKeyPath:@"status"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(showCommitView:)) {
		[menuItem setState:(contentController == _commitViewController) ? YES : NO];
		return ![self.repository isBareRepository];
	} else if ([menuItem action] == @selector(showHistoryView:)) {
		[menuItem setState:(contentController != _commitViewController) ? YES : NO];
		return ![self.repository isBareRepository];
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
	PBGitRef *ref = [self selectedRef];
	if (!ref)
		return NO;

	PBGitRef *remoteRef = [self.repository remoteRefForBranch:ref error:NULL];
	if (ref.isRemote || remoteRef) {
		menuItem.title = [NSString stringWithFormat:NSLocalizedString(localisationKeyWithRemote, @""), (!remoteRef ? ref.remoteName : remoteRef.remoteName)];
		menuItem.representedObject = ref;
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

	sidebarController = [[PBGitSidebarController alloc] initWithRepository:self.repository superController:self];
	_historyViewController = [[PBGitHistoryController alloc] initWithRepository:self.repository superController:self];
	_commitViewController = [[PBGitCommitController alloc] initWithRepository:self.repository superController:self];

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

- (void)showCommitView:(id)sender
{
	segmentedControl.integerValue = 1;
	[sidebarController selectStage];
}

- (void)showHistoryView:(id)sender
{
	segmentedControl.integerValue = 0;
	[sidebarController selectCurrentBranch];
}

- (IBAction)segmentedControlValueChanged:(NSSegmentedControl *)sender {
	if (sender.integerValue == 0) {
		[self showHistoryView:sender];
	} else {
		[self showCommitView:sender];
	}
}

- (void)showCommitHookFailedSheet:(NSString *)messageText infoText:(NSString *)infoText commitController:(PBGitCommitController *)controller
{
	[PBCommitHookFailedSheet beginWithMessageText:messageText
										 infoText:infoText
								 commitController:controller
	 completionHandler:^(id  _Nonnull sheet, NSModalResponse returnCode) {
		 if (returnCode != NSModalResponseOK) return;

		 [self->_commitViewController forceCommit:self];
	 }];
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
	[_historyViewController setHistorySearch:searchString mode:mode];
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

- (void)performFetchForRef:(PBGitRef *)ref
{
	NSString *desc = nil;
	if (ref == nil) {
		desc = [NSString stringWithFormat:@"Fetching all remotes"];
	} else if (ref.isRemote || ref.isRemoteBranch) {
		desc = [NSString stringWithFormat:@"Fetching branches from remote %@", ref.remoteName];
	} else {
		desc = [NSString stringWithFormat:@"Fetching tracking branch for %@", ref.shortName];
	}

	PBRemoteProgressSheet *progressSheet = [PBRemoteProgressSheet progressSheetWithTitle:@"Fetching remote…"
																			 description:desc
																		windowController:self];

	[progressSheet beginProgressSheetForBlock:^{
		NSError *error = nil;
		BOOL success = [self.repository fetchRemoteForRef:ref error:&error];
		return (success ? nil : error);
	} completionHandler:^(NSError *error) {
		if (error) {
			[self showErrorSheet:error];
		}
	}];
}

- (void)performPullForBranch:(PBGitRef *)branchRef remote:(PBGitRef *)remoteRef rebase:(BOOL)rebase {
	NSString *description = nil;
	if (!branchRef && !remoteRef) {
		NSAssert(NO, @"Asked to pull no branch from no remote");
	} else if (!branchRef) {
		description = [NSString stringWithFormat:@"Pulling all tracking branches from %@", remoteRef.remoteName];
	} else if (!remoteRef) {
		description = [NSString stringWithFormat:@"Pulling default remote for branch %@", branchRef.shortName];
	} else {
		description = [NSString stringWithFormat:@"Pulling branch %@ from remote %@", branchRef.shortName, remoteRef.remoteName];
	}

	PBRemoteProgressSheet *progressSheet = [PBRemoteProgressSheet progressSheetWithTitle:@"Pulling remote…"
																			 description:description
																		windowController:self];

	[progressSheet beginProgressSheetForBlock:^{
		NSError *error = nil;
		BOOL success = [self.repository pullBranch:branchRef fromRemote:remoteRef rebase:rebase error:&error];
		return success ? nil : error;
	} completionHandler:^(NSError *error) {
		if (error) {
			[self showErrorSheet:error];
		}
	}];
}

- (void)performPushForBranch:(PBGitRef *)branchRef toRemote:(PBGitRef *)remoteRef
{
	if ((!branchRef && !remoteRef)
		|| (branchRef && !branchRef.isBranch && !branchRef.isRemoteBranch && !branchRef.isTag)
		|| (remoteRef && !remoteRef.isRemote))
		return;

	// This block is actually responsible for performing the push operation
	void (^pushBlock)(void) = ^{
		NSString *description = nil;
		if (branchRef && remoteRef)
			description = [NSString stringWithFormat:@"Pushing %@ '%@' to remote %@", branchRef.refishType, branchRef.shortName, remoteRef.remoteName];
		else if (branchRef)
			description = [NSString stringWithFormat:@"Pushing %@ '%@' to default remote", branchRef.refishType, branchRef.shortName];
		else
			description = [NSString stringWithFormat:@"Pushing updates to remote %@", remoteRef.remoteName];

		PBRemoteProgressSheet *progressSheet = [PBRemoteProgressSheet progressSheetWithTitle:@"Pushing remote…"
																				 description:description
																			windowController:self];

		[progressSheet beginProgressSheetForBlock:^{
			NSError *error = nil;
			BOOL success = [self.repository pushBranch:branchRef toRemote:remoteRef error:&error];
			return (success ? nil : error);
		} completionHandler:^(NSError *error) {
			if (error) {
				[self showErrorSheet:error];
			}
		}];
	};

	if ([PBGitDefaults isDialogWarningSuppressedForDialog:kDialogConfirmPush]) {
		pushBlock();
		return;
	}

	NSString *description = nil;
	if (branchRef && remoteRef)
		description = [NSString stringWithFormat:@"Push %@ '%@' to remote %@", branchRef.refishType, branchRef.shortName, remoteRef.remoteName];
	else if (branchRef)
		description = [NSString stringWithFormat:@"Push %@ '%@' to default remote", branchRef.refishType, branchRef.shortName];
	else
		description = [NSString stringWithFormat:@"Push updates to remote %@", remoteRef.remoteName];

	NSString *sdesc = [NSString stringWithFormat:@"p%@", [description substringFromIndex:1]];
	NSAlert *alert = [[NSAlert alloc] init];
	alert.messageText = description;
	alert.informativeText = [NSString stringWithFormat:@"Are you sure you want to %@?", sdesc];
	[alert addButtonWithTitle:NSLocalizedString(@"Push", @"")];
	[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
	[alert setShowsSuppressionButton:YES];

	[alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
		if ([alert.suppressionButton state] == NSOnState)
			[PBGitDefaults suppressDialogWarningForDialog:kDialogConfirmPush];

		if (returnCode != NSAlertFirstButtonReturn) return;

		pushBlock();
	}];
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

#pragma mark IBActions

- (id <PBGitRefish>)refishForSender:(id)sender refishTypes:(NSArray *)types
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		id <PBGitRefish> refish = nil;
		if ([(refish = [(NSMenuItem *)sender representedObject]) conformsToProtocol:@protocol(PBGitRefish)]) {
			if (!types || [types indexOfObject:[refish refishType]] != NSNotFound)
				return refish;
		}
		NSString *remoteName = nil;
		if ([(remoteName = [(NSMenuItem *)sender representedObject]) isKindOfClass:[NSString class]]) {
			if ([types indexOfObject:kGitXRemoteType] != NSNotFound
				&& [self.repository.remotes indexOfObject:remoteName] != NSNotFound) {
				return [PBGitRef refFromString:[kGitXRemoteRefPrefix stringByAppendingString:remoteName]];
			}
		}

		return nil;
	}

	if ([types indexOfObject:kGitXCommitType] == NSNotFound)
		return nil;

	return _historyViewController.selectedCommits.firstObject;
}

- (PBGitRef *)selectedRef {
	id firstResponder = self.window.firstResponder;
	if (firstResponder == sidebarController.sourceView) {
		NSOutlineView *sourceView = sidebarController.sourceView;
		PBSourceViewItem *item = [sourceView itemAtRow:sourceView.selectedRow];
		PBGitRef *ref = item.ref;
		if (ref && (item.parent == sidebarController.remotes)) {
			ref = [PBGitRef refFromString:[kGitXRemoteRefPrefix stringByAppendingString:item.title]];
		}
		return ref;
	} else if (firstResponder == _historyViewController.commitList && _historyViewController.singleCommitSelected) {
		NSMutableArray *branchCommits = [NSMutableArray array];
		for (PBGitRef *ref in _historyViewController.selectedCommits.firstObject.refs) {
			if (!ref.isBranch) continue;
			[branchCommits addObject:ref];
		}
		return (branchCommits.count == 1 ? branchCommits.firstObject : nil);
	}
	return nil;
}

- (IBAction) showAddRemoteSheet:(id)sender
{
	[self addRemote:sender];
}

- (IBAction)addRemote:(id)sender
{
	[PBAddRemoteSheet beginSheetWithWindowController:self completionHandler:^(PBAddRemoteSheet *addSheet, NSModalResponse returnCode) {
		if (returnCode != NSModalResponseOK) return;

		NSString *remoteName = addSheet.remoteName.stringValue;
		NSString *remoteURL = addSheet.remoteURL.stringValue;

		NSString *description = [NSString stringWithFormat:@"Adding remote \"%@\"", remoteName];

		PBRemoteProgressSheet *progressSheet = [PBRemoteProgressSheet progressSheetWithTitle:@"Adding remote"
																				 description:description
																			windowController:self];
		[progressSheet beginProgressSheetForBlock:^{
			NSError *error = nil;
			BOOL success = [self.repository addRemote:remoteName withURL:remoteURL error:&error];
			return success ? nil : error;
		} completionHandler:^(NSError *error) {
			if (error) {
				[self showErrorSheet:error];
				return;
			}

			// Now fetch that remote
			PBGitRef *remoteRef = [self.repository refForName:remoteName];
			[self performFetchForRef:remoteRef];
		}];
	}];
}

- (IBAction)deleteRef:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType, kGitXRemoteType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;

	PBGitRef *ref = (PBGitRef *)refish;

	void (^performDelete)(void) = ^{
		NSError *error = nil;
		BOOL success = [self.repository deleteRef:ref error:&error];
		if (!success) {
			[self showErrorSheet:error];
		}
		return;
	};

	if ([PBGitDefaults isDialogWarningSuppressedForDialog:kDialogDeleteRef]) {
		performDelete();
		return;
	}

	NSString *ref_desc = [NSString stringWithFormat:@"%@ '%@'", [ref refishType], [ref shortName]];

	NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Delete %@?", ref_desc]
									 defaultButton:@"Delete"
								   alternateButton:@"Cancel"
									   otherButton:nil
						 informativeTextWithFormat:@"Are you sure you want to remove the %@?", ref_desc];
	[alert setShowsSuppressionButton:YES];

	[alert beginSheetModalForWindow:self.window
				  completionHandler:^(NSModalResponse returnCode) {
					  if ([[alert suppressionButton] state] == NSOnState)
						  [PBGitDefaults suppressDialogWarningForDialog:kDialogDeleteRef];

					  if (returnCode == NSModalResponseOK) {
						  performDelete();
					  }
				  }];
}

- (IBAction)fetchRemote:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType, kGitXRemoteType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;

	[self performFetchForRef:refish];
}

- (IBAction) fetchAllRemotes:(id)sender
{
	[self performFetchForRef:nil];
}

- (IBAction)pullRemote:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;

	[self performPullForBranch:refish remote:nil rebase:NO];
}

- (IBAction) pullRebaseRemote:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;

	[self performPullForBranch:refish remote:nil rebase:YES];
}

- (IBAction)pullDefaultRemote:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;

	[self performPullForBranch:refish remote:nil rebase:NO];
}

- (IBAction)pullRebaseDefaultRemote:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;
	[self performPullForBranch:refish remote:nil rebase:YES];
}

- (IBAction)pushUpdatesToRemote:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXRemoteType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;

	PBGitRef *remoteRef = [(PBGitRef *)refish remoteRef];

	[self performPushForBranch:nil toRemote:remoteRef];
}

- (IBAction)pushDefaultRemoteForRef:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType]];
	if (!refish || ![refish isKindOfClass:[PBGitRef class]])
		return;

	PBGitRef *ref = (PBGitRef *)refish;

	[self performPushForBranch:ref toRemote:nil];
}

- (IBAction)pushToRemote:(id)sender
{
	NSMenuItem *remoteSubmenu = sender;
	if (![remoteSubmenu isKindOfClass:[NSMenuItem class]]) return;

	id <PBGitRefish> ref = [self refishForSender:remoteSubmenu.parentItem refishTypes:@[kGitXBranchType]];
	if (!ref || ![ref isKindOfClass:[PBGitRef class]])
		return;

	id <PBGitRefish> remoteRef = [self refishForSender:sender refishTypes:@[kGitXRemoteType]];
	if (!remoteRef || ![remoteRef isKindOfClass:[PBGitRef class]])
		return;

	[self performPushForBranch:ref toRemote:remoteRef];
}

- (IBAction)checkout:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType, kGitXRemoteBranchType, kGitXCommitType, kGitXTagType]];
	if (!refish) return;

	NSError *error = nil;
	BOOL success = [self.repository checkoutRefish:refish error:&error];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)merge:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXBranchType, kGitXRemoteBranchType, kGitXCommitType, kGitXTagType]];
	if (!refish) return;

	NSError *error = nil;
	BOOL success = [self.repository mergeWithRefish:refish error:&error];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)rebase:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXCommitType]];
	if (!refish) return;

	NSError *error = nil;
	BOOL success = [self.repository rebaseBranch:nil onRefish:refish error:&error];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)rebaseHeadBranch:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXCommitType]];
	if (!refish || ![refish isKindOfClass:[PBGitCommit class]])
		return;

	NSError *error = nil;
	BOOL success = [self.repository rebaseBranch:nil onRefish:refish error:&error];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)cherryPick:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXCommitType]];
	if (!refish) return;

	NSError *error = nil;
	BOOL success = [self.repository cherryPickRefish:refish error:&error];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)stashSave:(id)sender
{
	NSError *error = nil;
	BOOL success = [self.repository stashSaveWithKeepIndex:NO error:&error];

	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)stashSaveWithKeepIndex:(id) sender
{
	NSError *error = nil;
	BOOL success = [self.repository stashSaveWithKeepIndex:YES error:&error];

	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)stashPop:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXStashType]];
	PBGitStash *stash = [self.repository stashForRef:refish];
	if (!stash) {
		stash = self.repository.stashes.firstObject;
	}

	NSError *error = nil;
	BOOL success = [self.repository stashPop:stash error:&error];
	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)stashApply:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXStashType]];
	PBGitStash *stash = [self.repository stashForRef:refish];
	NSError *error = nil;
	BOOL success = [self.repository stashApply:stash error:&error];

	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction)stashDrop:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXStashType]];
	PBGitStash *stash = [self.repository stashForRef:refish];
	NSError *error = nil;
	BOOL success = [self.repository stashDrop:stash error:&error];

	if (!success) {
		[self showErrorSheet:error];
	}
}

- (IBAction) openFiles:(id)sender {
	NSArray <NSURL *> *fileURLs = [self selectedURLsFromSender:sender];
	[self openURLs:fileURLs];
}

- (IBAction) revealInFinder:(id)sender
{
	[self revealURLsInFinder:@[self.repository.workingDirectoryURL]];
}

- (IBAction)openInTerminal:(id)sender
{
	[PBTerminalUtil runCommand:@"git status" inDirectory:self.repository.workingDirectoryURL];
}

- (IBAction) refresh:(id)sender
{
	[contentController refresh:self];
}

- (void) createBranch:(id)sender
{
	PBGitRef *currentRef = [self.repository.currentBranch ref];

	/* WIP: must check */
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:nil];
	if (!refish) {
		PBGitCommit *selectedCommit = _historyViewController.selectedCommits.firstObject;
		if (!selectedCommit || [selectedCommit hasRef:currentRef]) {
			refish = currentRef;
		} else {
			refish = selectedCommit;
		}
	}

	[PBCreateBranchSheet beginSheetWithRefish:refish windowController:self completionHandler:^(PBCreateBranchSheet *sheet, NSModalResponse returnCode) {
		if (returnCode != NSModalResponseOK) return;

		NSError *error = nil;
		BOOL success = [self.repository createBranch:[sheet.branchNameField stringValue] atRefish:sheet.startRefish error:&error];
		if (!success) {
			[self showErrorSheet:error];
			return;
		}

		[PBGitDefaults setShouldCheckoutBranch:sheet.shouldCheckoutBranch];

		if (sheet.shouldCheckoutBranch) {
			success = [self.repository checkoutRefish:sheet.selectedRef error:&error];
			if (!success) {
				[self showErrorSheet:error];
				return;
			}
		}
	}];
}

- (IBAction) createTag:(id)sender
{
	/* WIP: must check */
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:nil];
	if (!refish) {
		PBGitCommit *selectedCommit = _historyViewController.selectedCommits.firstObject;
		if (selectedCommit)
			refish = selectedCommit;
		else
			refish = self.repository.currentBranch.ref;
	}

	[PBCreateTagSheet beginSheetWithRefish:refish windowController:self completionHandler:^(PBCreateTagSheet *sheet, NSModalResponse returnCode) {
		if (returnCode != NSModalResponseOK) return;

		NSString *tagName = [sheet.tagNameField stringValue];
		NSString *message = [sheet.tagMessageText string];
		NSError *error = nil;
		BOOL success = [self.repository createTag:tagName message:message atRefish:sheet.targetRefish error:&error];
		if (!success) {
			[self showErrorSheet:error];
		}
	}];
}

- (IBAction)diffWithHEAD:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:nil];
	if (!refish)
		return;

	PBGitCommit *commit = [self.repository commitForRef:refish];

	NSString *diff = [self.repository performDiff:commit against:nil forFiles:nil];

	[PBDiffWindowController showDiff:diff];
}

- (IBAction)stashViewDiff:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXStashType]];
	PBGitStash *stash = [self.repository stashForRef:refish];
	[PBDiffWindowController showDiffWindowWithFiles:nil fromCommit:stash.ancestorCommit diffCommit:stash.commit];
}

- (IBAction)showTagInfoSheet:(id)sender
{
	id <PBGitRefish> refish = [self refishForSender:sender refishTypes:@[kGitXTagType]];
	if (!refish)
		return;

	PBGitRef *ref = (PBGitRef *)refish;

	NSError *error = nil;
	NSString *tagName = [ref tagName];
	NSString *tagRef = [@"refs/tags/" stringByAppendingString:tagName];
	GTObject *object = [self.repository.gtRepo lookUpObjectByRevParse:tagRef error:&error];
	if (!object) {
		NSLog(@"Couldn't look up ref %@:%@", tagRef, [error debugDescription]);
		return;
	}
	NSString *title = [NSString stringWithFormat:@"Info for tag: %@", tagName];
	NSString *info = @"";
	if ([object isKindOfClass:[GTTag class]]) {
		GTTag *tag = (GTTag*)object;
		info = tag.message;
	}

	[self showMessageSheet:title infoText:info];
}

@end
