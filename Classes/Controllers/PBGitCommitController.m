//
//  PBGitCommitController.m
//  GitX
//
//  Created by Pieter de Bie on 19-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitCommitController.h"
#import "NSFileHandleExt.h"
#import "PBChangedFile.h"
#import "PBWebChangesController.h"
#import "PBGitIndex.h"
#import "PBNiceSplitView.h"
#import "PBGitRepositoryWatcher.h"
#import "PBCommitMessageView.h"
#import "PBGitIndexController.h"

#import <ObjectiveGit/GTRepository.h>
#import <ObjectiveGit/GTConfiguration.h>

#define kCommitSplitViewPositionDefault @"Commit SplitView Position"
#define kControlsTabIndexCommit 0
#define kControlsTabIndexStash  1
#define kMinimalCommitMessageLength 3
#define kNotificationDictionaryDescriptionKey @"description"
#define kNotificationDictionaryMessageKey @"message"

@interface PBGitCommitController () <NSTextViewDelegate>
- (void)refreshFinished:(NSNotification *)notification;
- (void)commitWithVerification:(BOOL) doVerify;
- (void)commitStatusUpdated:(NSNotification *)notification;
- (void)commitFinished:(NSNotification *)notification;
- (void)commitFailed:(NSNotification *)notification;
- (void)commitHookFailed:(NSNotification *)notification;
- (void)amendCommit:(NSNotification *)notification;
- (void)indexChanged:(NSNotification *)notification;
- (void)indexOperationFailed:(NSNotification *)notification;
- (void)saveCommitSplitViewPosition;
@end

@implementation PBGitCommitController

@synthesize stashKeepIndex;

- (id)initWithRepository:(PBGitRepository *)theRepository superController:(PBGitWindowController *)controller
{
	if (!(self = [super initWithRepository:theRepository superController:controller]))
		return nil;

	PBGitIndex *index = theRepository.index;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFinished:) name:PBGitIndexFinishedIndexRefresh object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitStatusUpdated:) name:PBGitIndexCommitStatus object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitFinished:) name:PBGitIndexFinishedCommit object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitFailed:) name:PBGitIndexCommitFailed object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitHookFailed:) name:PBGitIndexCommitHookFailed object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(amendCommit:) name:PBGitIndexAmendMessageAvailable object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexChanged:) name:PBGitIndexIndexUpdated object:index];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexOperationFailed:) name:PBGitIndexOperationFailed object:index];

	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];

	commitMessageView.repository = self.repository;
	commitMessageView.delegate = self;

	[commitMessageView setTypingAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Menlo" size:12.0] forKey:NSFontAttributeName]];
	
	[unstagedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"hasUnstagedChanges == 1"]];
	[cachedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"hasStagedChanges == 1"]];
    [trackedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"status > 0"]];
	
	[unstagedFilesController setSortDescriptors:[NSArray arrayWithObjects:
		[[NSSortDescriptor alloc] initWithKey:@"status" ascending:false],
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true], nil]];
	[cachedFilesController setSortDescriptors:[NSArray arrayWithObject:
		[[NSSortDescriptor alloc] initWithKey:@"path" ascending:true]]];

    // listen for updates
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_repositoryUpdatedNotification:) name:PBGitRepositoryEventNotification object:repository];

	[cachedFilesController setAutomaticallyRearrangesObjects:NO];
	[unstagedFilesController setAutomaticallyRearrangesObjects:NO];

	[commitSplitView setHidden:YES];
	[self performSelector:@selector(restoreCommitSplitViewPositiion) withObject:nil afterDelay:0];
}

- (void) _repositoryUpdatedNotification:(NSNotification *)notification {
    PBGitRepositoryWatcherEventType eventType = [(NSNumber *)[[notification userInfo] objectForKey:kPBGitRepositoryEventTypeUserInfoKey] unsignedIntValue];
    if(eventType & (PBGitRepositoryWatcherEventTypeWorkingDirectory | PBGitRepositoryWatcherEventTypeIndex)){
      // refresh if the working directory or index is modified
      [self refresh:self];
    }
}

- (void) updateView
{
	[self refresh:nil];
}

- (void)closeView
{
	[self saveCommitSplitViewPosition];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[webController closeView];
}

- (NSResponder *)firstResponder;
{
	return commitMessageView;
}

- (PBGitIndex *) index {
	return repository.index;
}

- (void) commitWithVerification:(BOOL) doVerify
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:[repository.gitURL.path stringByAppendingPathComponent:@"MERGE_HEAD"]]) {
		NSString * message = NSLocalizedString(@"Cannot commit merges",
											   @"Title for sheet that GitX cannot create merge commits");
		NSString * info = NSLocalizedString(@"GitX cannot commit merges yet. Please commit your changes from the command line.",
											@"Information text for sheet that GitX cannot create merge commits");

		[self.windowController showMessageSheet:message infoText:info];
		return;
	}

	if ([[cachedFilesController arrangedObjects] count] == 0) {
		NSString * message = NSLocalizedString(@"No changes to commit",
											   @"Title for sheet that you need to stage changes before creating a commit");
		NSString * info = NSLocalizedString(@"You need to stage some changed files before committing by moving them to the list of Staged Changes.",
											@"Information text for sheet that you need to stage changes before creating a commit");

		[self.windowController showMessageSheet:message infoText:info];
		return;
	}

	NSString *commitMessage = [commitMessageView string];
	if (commitMessage.length < kMinimalCommitMessageLength) {
		NSString * message = NSLocalizedString(@"Missing commit message",
											   @"Title for sheet that you need to enter a commit message before creating a commit");
		NSString * info = [NSString stringWithFormat:
						   NSLocalizedString(@"Please enter a commit message at least %i characters long before commiting.",
											 @"Format for sheet that you need to enter a commit message before creating a commit giving the minimum length of the commit message required"),
						   kMinimalCommitMessageLength ];
		[self.windowController showMessageSheet:message infoText:info ];
		return;
	}

	[cachedFilesController setSelectionIndexes:[NSIndexSet indexSet]];
	[unstagedFilesController setSelectionIndexes:[NSIndexSet indexSet]];

	self.isBusy = YES;
	commitMessageView.editable = NO;

	[repository.index commitWithMessage:commitMessage andVerify:doVerify];
}

#pragma mark IBActions

- (IBAction)signOff:(id)sender
{
	NSError *error = nil;
	GTConfiguration *config = [repository.gtRepo configurationWithError:&error];
	NSString *userName = [config stringForKey:@"user.name"];
	NSString *userEmail = [config stringForKey:@"user.email"];
	if (!(userName && userEmail)) {
		return [[repository windowController]
				showMessageSheet:NSLocalizedString(@"User‘s name not set",
												   @"Title for sheet that the user’s name is not set in the git configuration")
				infoText:NSLocalizedString(@"Signing off a commit requires setting user.name and user.email in your git config",
										   @"Information text for sheet that the user’s name is not set in the git configuration")];
	}

	NSString *SOBline = [NSString stringWithFormat:NSLocalizedString(@"Signed-off-by: %@ <%@>",
																	 @"Signed off message format. Most likely this should not be localised."),
						 userName,
						 userEmail];

	if([commitMessageView.string rangeOfString:SOBline].location == NSNotFound) {
		NSArray *selectedRanges = [commitMessageView selectedRanges];
		commitMessageView.string = [NSString stringWithFormat:@"%@\n\n%@", commitMessageView.string, SOBline];
		[commitMessageView setSelectedRanges:selectedRanges];
	}
}

- (IBAction) refresh:(id) sender
{
	[controlsTabView selectTabViewItemAtIndex:kControlsTabIndexCommit];

	self.isBusy = YES;
	self.status = NSLocalizedString(@"Refreshing index…", @"Message in status bar while the index is refreshing");
	[repository.index refresh];

	// Reload refs (in case HEAD changed)
	[repository reloadRefs];
}

- (IBAction) stashChanges:(id)sender
{
    NSLog(@"stash changes: %@", stashKeepIndex ? @"keep index" : @"");
    [self.repository stashSaveWithKeepIndex:stashKeepIndex];
}

- (IBAction) commit:(id) sender
{
    [self commitWithVerification:YES];
}

- (IBAction) forceCommit:(id) sender
{
    [self commitWithVerification:NO];
}

# pragma mark PBGitIndex Notification handling

- (void)refreshFinished:(NSNotification *)notification
{
	self.isBusy = NO;
	self.status = NSLocalizedString(@"Index refresh finished", @"Message in status bar when refreshing the index is done");
}

- (void)commitStatusUpdated:(NSNotification *)notification
{
	self.status = notification.userInfo[kNotificationDictionaryDescriptionKey];
}

- (void)commitFinished:(NSNotification *)notification
{
	commitMessageView.editable = YES;
	commitMessageView.string = @"";
	[webController setStateMessage:notification.userInfo[kNotificationDictionaryDescriptionKey]];
}	

- (void)commitFailed:(NSNotification *)notification
{
	self.isBusy = NO;
	commitMessageView.editable = YES;

	NSString *reason = notification.userInfo[kNotificationDictionaryDescriptionKey];
	self.status = [NSString stringWithFormat:
				   NSLocalizedString(@"Commit failed: %@",
									 @"Message in status bar when creating a commit has failed, including the reason for the failure"),
				   reason];
	[repository.windowController showMessageSheet:NSLocalizedString(@"Commit failed", @"Title for sheet that creating a commit has failed")
										 infoText:reason];
}

- (void)commitHookFailed:(NSNotification *)notification
{
	self.isBusy = NO;
	commitMessageView.editable = YES;

	NSString *reason = notification.userInfo[kNotificationDictionaryDescriptionKey];
	self.status = [NSString stringWithFormat:
				   NSLocalizedString(@"Commit hook failed: %@",
									 @"Message in status bar when running a commit hook failed, including the reason for the failure"),
				   reason];
	[repository.windowController showCommitHookFailedSheet:NSLocalizedString(@"Commit hook failed", @"Title for sheet that running a commit hook has failed")
												  infoText:reason
										  commitController:self];
}

- (void)amendCommit:(NSNotification *)notification
{
	// Replace commit message with the old one if it's less than 3 characters long.
	// This is just a random number.
	if ([[commitMessageView string] length] > kMinimalCommitMessageLength) {
		return;
	}
	
	NSString *message = notification.userInfo[kNotificationDictionaryMessageKey];
	commitMessageView.string = message;
}

- (void)indexChanged:(NSNotification *)notification
{
	[cachedFilesController rearrangeObjects];
	[unstagedFilesController rearrangeObjects];
    
    NSUInteger tracked = [[trackedFilesController arrangedObjects] count];
    NSUInteger staged = [[cachedFilesController arrangedObjects] count];
    
    [commitButton setEnabled:(staged > 0)];
    [stashButton setEnabled:(staged > 0 || tracked > 0)];
}

- (void)indexOperationFailed:(NSNotification *)notification
{
	[repository.windowController showMessageSheet:NSLocalizedString(@"Index operation failed", @"Title for sheet that running an index operation has failed")
										 infoText:notification.userInfo[kNotificationDictionaryDescriptionKey]];
}


#pragma mark NSSplitView delegate methods

#define kCommitSplitViewTopViewMin 150
#define kCommitSplitViewBottomViewMin 100

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == commitSplitView)
		return kCommitSplitViewTopViewMin;

	return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == commitSplitView)
		return splitView.frame.size.height - splitView.dividerThickness - kCommitSplitViewBottomViewMin;

	return proposedMax;
}

// while the user resizes the window keep the lower (changes/message) view constant and just resize the upper view
// unless the upper view gets too small
- (void)resizeCommitSplitView
{
	NSRect newFrame = [commitSplitView frame];

	CGFloat dividerThickness = commitSplitView.dividerThickness;

	NSView *upperView = [[commitSplitView subviews] objectAtIndex:0];
	NSRect upperFrame = [upperView frame];
	upperFrame.size.width = newFrame.size.width;

	NSView *lowerView = [[commitSplitView subviews] objectAtIndex:1];
	NSRect lowerFrame = [lowerView frame];
	lowerFrame.size.width = newFrame.size.width;

	upperFrame.size.height = newFrame.size.height - lowerFrame.size.height - dividerThickness;
	if (upperFrame.size.height < kCommitSplitViewTopViewMin)
		upperFrame.size.height = kCommitSplitViewTopViewMin;

	lowerFrame.size.height = newFrame.size.height - upperFrame.size.height - dividerThickness;
	lowerFrame.origin.y = newFrame.size.height - lowerFrame.size.height;

	[upperView setFrame:upperFrame];
	[lowerView setFrame:lowerFrame];
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if (splitView == commitSplitView)
		[self resizeCommitSplitView];
}

// NSSplitView does not save and restore the position of the splitView correctly so do it manually
- (void)saveCommitSplitViewPosition
{
	CGFloat position = [[[commitSplitView subviews] objectAtIndex:0] frame].size.height;
	[[NSUserDefaults standardUserDefaults] setDouble:position forKey:kCommitSplitViewPositionDefault];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

// make sure this happens after awakeFromNib
- (void)restoreCommitSplitViewPositiion
{
	CGFloat position = [[NSUserDefaults standardUserDefaults] doubleForKey:kCommitSplitViewPositionDefault];
	if (position < 1.0)
		position = commitSplitView.frame.size.height - 225;

	[commitSplitView setPosition:position ofDividerAtIndex:0];
	[commitSplitView setHidden:NO];
}

#pragma mark Handle "alt" key-down/up events
// to toggle commit/stash controls

- (void)flagsChanged:(NSEvent *)theEvent
{
    BOOL altDown = !!([theEvent modifierFlags] & NSAlternateKeyMask);
    NSInteger currIndex = [controlsTabView indexOfTabViewItem:controlsTabView.selectedTabViewItem];
    int desiredIndex = altDown ? kControlsTabIndexStash : kControlsTabIndexCommit;
    if (currIndex != desiredIndex) {
        [controlsTabView selectTabViewItemAtIndex:desiredIndex];
    }
}

#pragma mark NSTextView delegate methods

- (void)focusTable:(NSTableView *)table
{
    if ([table numberOfRows] > 0) {
        if ([table numberOfSelectedRows] == 0) {
            [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
        [[table window] makeFirstResponder:table];
    }
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;
{
    if (commandSelector == @selector(insertTab:)) {
        [self focusTable:indexController.stagedTable];
        return YES;
    } else if (commandSelector == @selector(insertBacktab:)) {
        [self focusTable:indexController.unstagedTable];
        return YES;
	}
    return NO;
}

# pragma mark Key View Chain

-(NSView *)nextKeyViewFor:(NSView *)view
{
    NSView * next = nil;
    if (view == indexController.unstagedTable) {
        next = commitMessageView;
    }
    else if (view == commitMessageView) {
        next = indexController.stagedTable;
    }
    else if (view == indexController.stagedTable) {
        next = commitButton;
    }
    return next;
}

-(NSView *)previousKeyViewFor:(NSView *)view
{
    NSView * next = nil;
    if (view == indexController.stagedTable) {
        next = commitMessageView;
    }
    else if (view == commitMessageView) {
        next = indexController.unstagedTable;
    }
    return next;
}

@end
