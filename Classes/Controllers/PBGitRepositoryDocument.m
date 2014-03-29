//
//  PBGitRepositoryDocument.m
//  GitX
//
//  Created by Etienne on 31/07/2014.
//
//

#import "PBGitRepositoryDocument.h"
#import "PBGitRepository.h"
#import "PBGitWindowController.h"
#import "PBGitRevSpecifier.h"
#import "PBGitBinary.h"
#import "GitXScriptingConstants.h"
#import "PBRepositoryFinder.h"
#import "PBGitDefaults.h"

NSString *PBGitRepositoryDocumentType = @"Git Repository";

@implementation PBGitRepositoryDocument

- (id)init
{
    self = [super init];
    if (!self) return nil;

    return self;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if (![PBGitBinary path])
	{
		if (outError) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[PBGitBinary notFoundError]
																 forKey:NSLocalizedRecoverySuggestionErrorKey];
			*outError = [NSError errorWithDomain:PBGitRepositoryErrorDomain code:0 userInfo:userInfo];
		}
		return NO;
	}

	BOOL isDirectory = FALSE;
	[[NSFileManager defaultManager] fileExistsAtPath:[absoluteURL path] isDirectory:&isDirectory];
	if (!isDirectory) {
		if (outError) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:@"Reading files is not supported."
																 forKey:NSLocalizedRecoverySuggestionErrorKey];
			*outError = [NSError errorWithDomain:PBGitRepositoryErrorDomain code:0 userInfo:userInfo];
		}
		return NO;
	}

	_repository = [[PBGitRepository alloc] initWithURL:absoluteURL error:outError];

	return YES;
}

- (void)close
{
	/* FIXME: Check that this deallocs the repo */
//	[revisionList cleanup];

	[super close];
}

- (BOOL)isDocumentEdited
{
	return NO;
}

- (NSString *)displayName
{
    // Build our display name depending on the current HEAD and whether it's detached or not
    if (self.repository.gtRepo.isHEADDetached)
		return [NSString localizedStringWithFormat:@"%@ (detached HEAD)", self.repository.projectName];

	return [NSString localizedStringWithFormat:@"%@ (branch: %@)", self.repository.projectName, [self.repository.headRef description]];
}

- (void)makeWindowControllers
{
    // Create our custom window controller
#ifndef CLI
	[self addWindowController: [[PBGitWindowController alloc] initWithRepository:self.repository displayDefault:YES]];
#endif
}

- (PBGitWindowController *)windowController
{
	if ([[self windowControllers] count] == 0)
		return NULL;

	return [[self windowControllers] objectAtIndex:0];
}

- (IBAction)showCommitView:(id)sender {
	[[self windowController] showCommitView:sender];
}

- (IBAction)showHistoryView:(id)sender {
	[[self windowController] showHistoryView:sender];
}

- (void)selectRevisionSpecifier:(PBGitRevSpecifier *)specifier {
	PBGitRevSpecifier *spec = [self.repository addBranch:specifier];
	self.repository.currentBranch = spec;
	[self showHistoryView:self];
}

- (void)showWindows
{
	/* see if the current appleEvent has the command line arguments from the gitx cli
	 * this could be from an openApplication or an openDocument apple event
	 * when opening a repository this is called before the sidebar controller gets it's awakeFromNib: message
	 * if the repository is already open then this is also a good place to catch the event as the window is about to be brought forward
	 */
	NSAppleEventDescriptor *currentAppleEvent = [[NSAppleEventManager sharedAppleEventManager] currentAppleEvent];

	if (currentAppleEvent) {
		NSAppleEventDescriptor *eventRecord = [currentAppleEvent paramDescriptorForKeyword:keyAEPropData];

		// on app launch there may be many repositories opening, so double check that this is the right repo
		NSString *path = [[eventRecord paramDescriptorForKeyword:typeFileURL] stringValue];
		if (path) {
			NSURL *workingDirectory = [NSURL URLWithString:path];
			if ([[PBRepositoryFinder gitDirForURL:workingDirectory] isEqual:[self fileURL]]) {
				NSAppleEventDescriptor *argumentsList = [eventRecord paramDescriptorForKeyword:kGitXAEKeyArgumentsList];
				[self handleGitXScriptingArguments:argumentsList inWorkingDirectory:workingDirectory];

				// showWindows may be called more than once during app launch so remove the CLI data after we handle the event
				[currentAppleEvent removeDescriptorWithKeyword:keyAEPropData];
			}
		}
	}

	[[[self windowController] window] setTitle:[self displayName]];

	[super showWindows];
}

#pragma mark -
#pragma mark NSResponder methods

- (NSArray *)selectedURLsFromSender:(id)sender {
	NSArray *selectedFiles = [sender representedObject];
	if ([selectedFiles count] == 0)
		return nil;

	NSURL *workingDirectoryURL = self.repository.workingDirectoryURL;
	NSMutableArray *URLs = [NSMutableArray array];
    for (id file in selectedFiles) {
        NSString *path = file;
        // Those can be PBChangedFiles sent by PBGitIndexController. Get their path.
        if ([file respondsToSelector:@selector(path)]) {
            path = [file path];
        }

        if (![path isKindOfClass:[NSString class]])
            continue;
        [URLs addObject:[workingDirectoryURL URLByAppendingPathComponent:path]];
    }

    return URLs;
}

- (IBAction)showInFinderAction:(id)sender {
    NSArray *URLs = [self selectedURLsFromSender:sender];
    if ([URLs count] == 0)
        return;

    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:URLs];
}

- (IBAction)openFilesAction:(id)sender {
    NSArray *URLs = [self selectedURLsFromSender:sender];

    if ([URLs count] == 0)
        return;

    [[NSWorkspace sharedWorkspace] openURLs:URLs
                    withAppBundleIdentifier:nil
                                    options:0
             additionalEventParamDescriptor:nil
                          launchIdentifiers:NULL];
}

#pragma mark -
#pragma mark AppleScript support

- (void)handleRevListArguments:(NSArray *)arguments inWorkingDirectory:(NSURL *)workingDirectory
{
	if (![arguments count])
		return;

	PBGitRevSpecifier *revListSpecifier = nil;

	// the argument may be a branch or tag name but will probably not be the full reference
	if ([arguments count] == 1) {
		PBGitRef *refArgument = [self.repository refForName:[arguments lastObject]];
		if (refArgument) {
			revListSpecifier = [[PBGitRevSpecifier alloc] initWithRef:refArgument];
			revListSpecifier.workingDirectory = workingDirectory;
		}
	}

	if (!revListSpecifier) {
		revListSpecifier = [[PBGitRevSpecifier alloc] initWithParameters:arguments];
		revListSpecifier.workingDirectory = workingDirectory;
	}

	self.repository.currentBranch = [self.repository addBranch:revListSpecifier];
	[PBGitDefaults setShowStageView:NO];
	[self.windowController showHistoryView:self];
}

- (void)handleBranchFilterEventForFilter:(PBGitXBranchFilterType)filter additionalArguments:(NSMutableArray *)arguments inWorkingDirectory:(NSURL *)workingDirectory
{
	self.repository.currentBranchFilter = filter;
	[PBGitDefaults setShowStageView:NO];
	[self.windowController showHistoryView:self];

	// treat any additional arguments as a rev-list specifier
	if ([arguments count] > 1) {
		[arguments removeObjectAtIndex:0];
		[self handleRevListArguments:arguments inWorkingDirectory:workingDirectory];
	}
}

- (void)handleGitXScriptingArguments:(NSAppleEventDescriptor *)argumentsList inWorkingDirectory:(NSURL *)workingDirectory
{
	NSMutableArray *arguments = [NSMutableArray array];
	uint argumentsIndex = 1; // AppleEvent list descriptor's are one based
	while(1) {
		NSAppleEventDescriptor *arg = [argumentsList descriptorAtIndex:argumentsIndex++];
		if (arg)
			[arguments addObject:[arg stringValue]];
		else
			break;
	}

	if (![arguments count])
		return;

	NSString *firstArgument = [arguments objectAtIndex:0];

	if ([firstArgument isEqualToString:@"-c"] || [firstArgument isEqualToString:@"--commit"]) {
		[PBGitDefaults setShowStageView:YES];
		[self.windowController showCommitView:self];
		return;
	}

	if ([firstArgument isEqualToString:@"--all"]) {
		[self handleBranchFilterEventForFilter:kGitXAllBranchesFilter additionalArguments:arguments inWorkingDirectory:workingDirectory];
		return;
	}

	if ([firstArgument isEqualToString:@"--local"]) {
		[self handleBranchFilterEventForFilter:kGitXLocalRemoteBranchesFilter additionalArguments:arguments inWorkingDirectory:workingDirectory];
		return;
	}

	if ([firstArgument isEqualToString:@"--branch"]) {
		[self handleBranchFilterEventForFilter:kGitXSelectedBranchFilter additionalArguments:arguments inWorkingDirectory:workingDirectory];
		return;
	}

	// if the argument is not a known command then treat it as a rev-list specifier
	[self handleRevListArguments:arguments inWorkingDirectory:workingDirectory];
}

// for the scripting bridge
- (void)findInModeScriptCommand:(NSScriptCommand *)command
{
	NSDictionary *arguments = [command arguments];
	NSString *searchString = [arguments objectForKey:kGitXFindSearchStringKey];
	if (searchString) {
		NSInteger mode = [[arguments objectForKey:kGitXFindInModeKey] integerValue];
		[PBGitDefaults setShowStageView:NO];
		[self.windowController showHistoryView:self];
		[self.windowController setHistorySearch:searchString mode:mode];
	}
}

@end
