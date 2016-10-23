//
//  PBWebGitController.m
//  GitTest
//
//  Created by Pieter de Bie on 14-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBWebHistoryController.h"
#import "PBGitDefaults.h"
#import <ObjectiveGit/GTConfiguration.h>
#import "PBGitRef.h"
#import "PBGitRevSpecifier.h"

@implementation PBWebHistoryController

@synthesize diff;

- (void) awakeFromNib
{
	startFile = @"history";
	repository = historyController.repository;
	[super awakeFromNib];
	[historyController addObserver:self forKeyPath:@"webCommits" options:0 context:@"ChangedCommit"];
}

- (void)closeView
{
	[[self script] setValue:nil forKey:@"commit"];
	[historyController removeObserver:self forKeyPath:@"webCommits"];

	[super closeView];
}

- (void) didLoad
{
	currentOID = nil;
	[self changeContentTo:historyController.webCommits];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(__bridge NSString *)context isEqualToString: @"ChangedCommit"])
		[self changeContentTo:historyController.webCommits];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) changeContentTo:(NSArray<PBGitCommit *> *)commits
{
	if (commits == nil || commits.count == 0 || !finishedLoading) {
		return;
	}
	
	if (commits.count == 1) {
		[self changeContentToCommit:commits.firstObject];
	}
	else {
		[self changeContentToMultipleSelectionMessage];
	}
}

- (void) changeContentToMultipleSelectionMessage {
	NSArray *arguments = @[
			@[NSLocalizedString(@"Multiple commits are selected.", @"Multiple selection Message: Title"),
			  NSLocalizedString(@"Use the Copy command to copy their information.", @"Multiple selection Message: Copy Command"),
			  NSLocalizedString(@"Or select a single commit to see its diff.", @"Multiple selection Message: Diff Hint")
			  ]];
	[[self script] callWebScriptMethod:@"showMultipleSelectionMessage" withArguments:arguments];
}

static NSString *deltaTypeName(GTDiffDeltaType t) {
	switch (t) {
		case GTDiffFileDeltaUnmodified: return @"unmodified";
		case GTDiffFileDeltaAdded: return @"added";
		case GTDiffFileDeltaDeleted: return @"removed";
		case GTDiffFileDeltaModified: return @"modified";
		case GTDiffFileDeltaRenamed: return @"renamed";
		case GTDiffFileDeltaCopied: return @"copied";
		case GTDiffFileDeltaIgnored: return @"ignored";
		case GTDiffFileDeltaUntracked: return @"untracked";
		case GTDiffFileDeltaTypeChange: return @"type changed";
	}
}

- (void) changeContentToCommit:(PBGitCommit *)commit
{
	// The sha is the same, but refs may have changed. reload it lazy
	if ([currentOID isEqual:commit.OID])
	{
		[[self script] callWebScriptMethod:@"reload" withArguments: nil];
		return;
	}

	NSArray *arguments = @[commit, [[[historyController repository] headRef] simpleRef]];
	id scriptResult = [[self script] callWebScriptMethod:@"loadCommit" withArguments: arguments];
	if (!scriptResult) {
		// the web view is not really ready for scripting???
		[self performSelector:_cmd withObject:commit afterDelay:0.05];
		return;
	}
	currentOID = commit.OID;

	GTDiffFindOptionsFlags flags = GTDiffFindOptionsFlagsFindRenames;
	if (![PBGitDefaults showWhitespaceDifferences]) {
		flags |= GTDiffFindOptionsFlagsIgnoreWhitespace;
	}
	NSError *err = nil;
	GTDiff *d = // TODO async?
	    [GTDiff diffOldTree:commit.gtCommit.parents.firstObject.tree
	            withNewTree:commit.gtCommit.tree
	           inRepository:[repository gtRepo]
	                options:@{
	                    GTDiffFindOptionsFlagsKey : @(flags)
	                }
	                  error:&err];
	if (!d) {
		NSLog(@"Commit summary diff error: %@", err);
		return;
	}
	NSMutableArray *fileDeltas = [NSMutableArray array];
	[d enumerateDeltasUsingBlock:^(GTDiffDelta *_Nonnull delta, BOOL *_Nonnull stop) {
		NSUInteger numLinesAdded = 0;
		NSUInteger numLinesRemoved = 0;
		NSError *err = nil;
		GTDiffPatch *patch = [delta generatePatch:&err];
		if (patch) {
			numLinesAdded = patch.addedLinesCount;
			numLinesRemoved = patch.deletedLinesCount;
		} else {
			NSLog(@"generatePatch error: %@", err);
		}
		[fileDeltas addObject:@{
			@"filename" : delta.newFile.path,
			@"oldFilename" : delta.oldFile.path,
			@"newFilename" : delta.newFile.path,
			@"changeType" : deltaTypeName(delta.type),
			@"numLinesAdded" : @(numLinesAdded),
			@"numLinesRemoved" : @(numLinesRemoved),
			@"binary" :
			    [NSNumber numberWithBool:(delta.flags & GTDiffFileFlagBinary) != 0],
		}];
	}];
	NSDictionary *summaryDict = @{
		@"filesInfo" : fileDeltas,
	};
	NSString *summary =
	    [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:summaryDict
	                                                                   options:0
	                                                                     error:&err]
	                          encoding:NSUTF8StringEncoding];
	if (!summary) {
		NSLog(@"Commit summary JSON error: %@", err);
		return;
	}

	[self.view.windowScriptObject callWebScriptMethod:@"loadCommitSummary" withArguments:@[summary]];

    // Now load the full diff
	NSMutableArray *taskArguments = [NSMutableArray arrayWithObjects:@"show", @"--pretty=raw", @"-M", @"--no-color", currentOID.SHA, nil];

	if (![PBGitDefaults showWhitespaceDifferences])
		[taskArguments insertObject:@"-w" atIndex:1];

	NSFileHandle *handle = [repository handleForArguments:taskArguments];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	// Remove notification, in case we have another one running
	[nc removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:nil];
	[nc addObserver:self selector:@selector(commitFullDiffLoaded:) name:NSFileHandleReadToEndOfFileCompletionNotification object:handle];
	[handle readToEndOfFileInBackgroundAndNotify];
}

- (void)commitFullDiffLoaded:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:nil];

	NSData *data = [[notification userInfo] valueForKey:NSFileHandleNotificationDataItem];
	if (!data)
		return;

	NSString *fullDiff = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!fullDiff)
		fullDiff = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];

	if (!fullDiff)
		return;

	[self.view.windowScriptObject callWebScriptMethod:@"loadCommitFullDiff" withArguments:[NSArray arrayWithObject:fullDiff]];
}

- (void)selectCommit:(NSString *)sha
{
	[historyController selectCommit: [GTOID oidWithSHA: sha]];
}

- (void) sendKey: (NSString*) key
{
	id script = self.view.windowScriptObject;
	[script callWebScriptMethod:@"handleKeyFromCocoa" withArguments: [NSArray arrayWithObject:key]];
}

- (void) copySource
{
	NSString *source = [(DOMHTMLElement *)self.view.mainFrame.DOMDocument.documentElement outerHTML];
	NSPasteboard *a =[NSPasteboard generalPasteboard];
	[a declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[a setString:source forType: NSStringPboardType];
}

- (NSArray *)	   webView:(WebView *)sender
contextMenuItemsForElement:(NSDictionary *)element
		  defaultMenuItems:(NSArray *)defaultMenuItems
{
	DOMNode *node = [element valueForKey:@"WebElementDOMNode"];

	while (node) {
		// Every ref has a class name of 'refs' and some other class. We check on that to see if we pressed on a ref.
		if ([[node className] hasPrefix:@"refs "]) {
			NSString *selectedRefString = [[[node childNodes] item:0] textContent];
			for (PBGitRef *ref in historyController.webCommits.firstObject.refs) {
				if ([[ref shortName] isEqualToString:selectedRefString])
					return [contextMenuDelegate menuItemsForRef:ref];
			}
			NSLog(@"Could not find selected ref!");
			return defaultMenuItems;
		}
		if ([node hasAttributes] && [[node attributes] getNamedItem:@"representedFile"])
			return [historyController menuItemsForPaths:[NSArray arrayWithObject:[[[node attributes] getNamedItem:@"representedFile"] nodeValue]]];
        else if ([[node class] isEqual:[DOMHTMLImageElement class]]) {
            // Copy Image is the only menu item that makes sense here since we don't need
			// to download the image or open it in a new window (besides with the
			// current implementation these two entries can crash GitX anyway)
			for (NSMenuItem *item in defaultMenuItems)
				if ([item tag] == WebMenuItemTagCopyImageToClipboard)
					return [NSArray arrayWithObject:item];
			return nil;
        }

		node = [node parentNode];
	}

	return defaultMenuItems;
}


// Open external links in the default browser
-   (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
   		  request:(NSURLRequest *)request
     newFrameName:(NSString *)frameName
 decisionListener:(id < WebPolicyDecisionListener >)listener
{
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
}

- getConfig:(NSString *)key
{
	NSError *error = nil;
    GTConfiguration* config = [historyController.repository.gtRepo configurationWithError:&error];
	return [config stringForKey:key];
}


- (void) preferencesChanged
{
	[[self script] callWebScriptMethod:@"enableFeatures" withArguments:nil];
}

@end
