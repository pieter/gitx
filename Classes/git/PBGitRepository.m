//
//  PBGitRepository.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRepository.h"

#import "PBGitRepository_PBGitBinarySupport.h"
#import "PBGitCommit.h"
#import "PBGitIndex.h"
#import "PBGitWindowController.h"
#import "PBGitRepositoryDocument.h"
#import "PBGitBinary.h"

#import "NSFileHandleExt.h"
#import "PBEasyPipe.h"
#import "PBGitRef.h"
#import "PBGitRevSpecifier.h"
#import "PBRemoteProgressSheet.h"
#import "PBGitRevList.h"
#import "PBGitDefaults.h"
#import "GitXScriptingConstants.h"
#import "PBHistorySearchController.h"
#import "PBGitRepositoryWatcher.h"
#import "PBRepositoryFinder.h"
#import "PBGitHistoryList.h"
#import "PBGitStash.h"
#import "PBError.h"

@interface PBGitRepository () {
	__strong PBGitRepositoryWatcher *watcher;
	__strong PBGitRevSpecifier *_headRef; // Caching
	__strong GTOID* _headOID;
	__strong GTRepository* _gtRepo;
	PBGitIndex *_index;
}

@property (nonatomic, strong) NSNumber *hasSVNRepoConfig;

@end

@implementation PBGitRepository

@synthesize revisionList, branchesSet, currentBranch, currentBranchFilter, hasChanged, refs;

#pragma mark -
#pragma mark Memory management

- (id)init
{
    self = [super init];
    if (!self) return nil;

	self.branchesSet = [NSMutableOrderedSet orderedSet];
    self.submodules = [NSMutableArray array];
	currentBranchFilter = [PBGitDefaults branchFilter];
    return self;
}

- (id)initWithURL:(NSURL *)repositoryURL error:(NSError **)error
{
	self = [self init];
	if (!self) return nil;

	NSError *gtError = nil;
	NSURL *repoURL = [PBRepositoryFinder gitDirForURL:repositoryURL];
	_gtRepo = [GTRepository repositoryWithURL:repoURL error:&gtError];
	if (!_gtRepo) {
		if (error) {
			*error = [NSError pb_errorWithDescription:NSLocalizedString(@"Repository initialization failed", @"")
										failureReason:[NSString stringWithFormat:NSLocalizedString(@"%@ does not appear to be a git repository.", @""), repositoryURL.path]
									  underlyingError:gtError];
		}
		return nil;
	}

	revisionList = [[PBGitHistoryList alloc] initWithRepository:self];

	[self reloadRefs];

    // Setup the FSEvents watcher to fire notifications when things change
    watcher = [[PBGitRepositoryWatcher alloc] initWithRepository:self];

	return self;
}

- (void) dealloc
{
	// NSLog(@"Dealloc of repository");
	[watcher stop];
}

#pragma mark -
#pragma mark Backward-compatibility
// PBGitRepository is responsible for both repository actions and document management
// This is here for the time being while the controller code gets updated to use PBGitRepositoryDocument.

- (PBGitWindowController *)windowController {
	return _document.windowController;
}

#pragma mark -
#pragma mark Properties/General methods

- (NSURL *)getIndexURL
{
	NSError *error = nil;
	GTIndex *index = [self.gtRepo indexWithError:&error];
    if (index == nil) {
        NSLog(@"getIndexURL failed with error %@", error);
        return nil;
    }
	NSURL* result = index.fileURL;
	return result;
}

- (BOOL)isBareRepository
{
    return self.gtRepo.isBare;
}

- (BOOL)isShallowRepository
{
	// Using low-level function because GTRepository does not currently
    // expose this information itself.
	return (BOOL)git_repository_is_shallow(self.gtRepo.git_repository);
}

- (BOOL)readHasSVNRemoteFromConfig
{
	NSError *error = nil;
	GTConfiguration *config = [self.gtRepo configurationWithError:&error];
	NSArray *allKeys = config.configurationKeys;
	for (NSString *key in allKeys) {
		if ([key hasPrefix:@"svn-remote."]) {
			return TRUE;
		}
	}
	return false;
}

- (BOOL)hasSVNRemote
{
	if (!self.hasSVNRepoConfig) {
		self.hasSVNRepoConfig = @([self readHasSVNRemoteFromConfig]);
	}
	return [self.hasSVNRepoConfig boolValue];
}

- (NSURL *)gitURL {
    return self.gtRepo.gitDirectoryURL;
}

- (NSURL *)workingDirectoryURL {
    return self.gtRepo.fileURL;
}

- (NSString *)workingDirectory
{
    return self.workingDirectoryURL.path;
}

- (void)forceUpdateRevisions
{
	[revisionList forceUpdate];
}

- (NSString *)projectName
{
	NSString* result = [self.workingDirectory lastPathComponent];
	return result;
}

// Get the .gitignore file at the root of the repository
- (NSString *)gitIgnoreFilename
{
	return [[self workingDirectory] stringByAppendingPathComponent:@".gitignore"];
}

- (void)addRef:(GTReference *)gtRef
{
	GTObject *refTarget = gtRef.resolvedTarget;
	if (![refTarget isKindOfClass:[GTObject class]]) {
		NSLog(@"Tried to add invalid ref %@ -> %@", gtRef, refTarget);
		return;
	}

	GTOID *sha = refTarget.OID;
	if (!sha) {
		NSLog(@"Couldn't determine sha for ref %@ -> %@", gtRef, refTarget);
		return;
	}

	PBGitRef* ref = [[PBGitRef alloc] initWithString:gtRef.name];
//	NSLog(@"addRef %@ %@ at %@", ref.type, gtRef.name, [sha string]);
	NSMutableArray* curRefs = refs[sha];
	if ( curRefs != nil ) {
		if ([curRefs containsObject:ref]) {
			NSLog(@"Duplicate ref shouldn't be added: %@", ref);
			return;
		}
		[curRefs addObject:ref];
	} else {
		refs[sha] = [NSMutableArray arrayWithObject:ref];
	}
}

- (void)loadSubmodules
{
    self.submodules = [NSMutableArray array];

    [self.gtRepo enumerateSubmodulesRecursively:NO usingBlock:^(GTSubmodule *gtSubmodule, NSError *error, BOOL *stop) {
		[self.submodules addObject:gtSubmodule];
    }];
}

- (void) reloadRefs
{
	// clear out ref caches
	_headRef = nil;
	_headOID = nil;
	self->refs = [NSMutableDictionary dictionary];
	
	NSError* error = nil;
	NSArray* allRefs = [self.gtRepo referenceNamesWithError:&error];

	if ([self.gtRepo isHEADDetached]) {
		// Add HEAD when we're detached
		allRefs = [allRefs arrayByAddingObject:@"HEAD"];
	}
	
	// load all named refs
	NSMutableOrderedSet *oldBranches = [self.branchesSet mutableCopy];
	for (NSString* referenceName in allRefs)
	{
		GTReference* gtRef = [self.gtRepo lookUpReferenceWithName:referenceName error:&error];
		
		if (gtRef == nil)
		{
			NSLog(@"Reference \"%@\" could not be found in the repository", referenceName);
			if (error)
			{
				NSLog(@"Error loading reference was: %@", error);
			}
			continue;
		}
		if (gtRef.remote && gtRef.referenceType == GTReferenceTypeSymbolic) {
			// Hide remote symbolic references like origin/HEAD
			continue;
		}
		PBGitRef* gitRef = [PBGitRef refFromString:referenceName];
		PBGitRevSpecifier* revSpec = [[PBGitRevSpecifier alloc] initWithRef:gitRef];
		[self addBranch:revSpec];
		[self addRef:gtRef];
		[oldBranches removeObject:revSpec];
	}
	
	for (PBGitRevSpecifier *branch in oldBranches)
		if ([branch isSimpleRef] && ![branch isEqual:[self headRef]])
			[self removeBranch:branch];


    [self loadSubmodules];
    
	[self willChangeValueForKey:@"refs"];
	[self willChangeValueForKey:@"stashes"];
	[self didChangeValueForKey:@"refs"];
	[self didChangeValueForKey:@"stashes"];
}

- (void) lazyReload
{
	if (!hasChanged)
		return;

	[self.revisionList updateHistory];
	hasChanged = NO;
}

- (PBGitRevSpecifier *)headRef
{
	if (_headRef)
		return _headRef;

	GTReference *branchRef = [self parseSymbolicReference: @"HEAD"];
	if (branchRef && [branchRef.name hasPrefix:@"refs/heads/"])
		_headRef = [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:branchRef.name]];
	else
		_headRef = [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:@"HEAD"]];

	_headOID = branchRef.OID;

	return _headRef;
}

- (GTOID *)headOID
{
	if (! _headOID)
		[self headRef];

	return _headOID;
}

- (PBGitCommit *)headCommit
{
	return [self commitForOID:self.headOID];
}

- (GTOID *)OIDForRef:(PBGitRef *)ref
{
	if (!ref)
		return nil;
	
	for (GTOID *sha in refs)
	{
		NSMutableSet *refsForSha = [refs objectForKey:sha];
		for (PBGitRef *existingRef in refsForSha)
		{
			if ([existingRef isEqualToRef:ref])
			{
				return sha;
			}
		}
    }
    
	
	NSError* error = nil;
	GTReference *gtRef = [self.gtRepo lookUpReferenceWithName:ref.ref error:&error];
	if (!gtRef)
	{
		NSLog(@"Error looking up ref for %@", ref.ref);
		return nil;
	}
	return gtRef.OID;
}

- (PBGitCommit *)commitForRef:(PBGitRef *)ref
{
	if (!ref)
		return nil;

	return [self commitForOID:[self OIDForRef:ref]];
}

- (PBGitCommit *)commitForOID:(GTOID *)sha
{
	if (!sha)
		return nil;
	NSArray *revList = revisionList.projectCommits;

    if (!revList) {
        [revisionList forceUpdate];
        revList = revisionList.projectCommits;
    }
	for (PBGitCommit *commit in revList)
		if ([commit.OID isEqual:sha])
			return commit;

	return nil;
}

- (BOOL)isOIDOnSameBranch:(GTOID *)branchOID asOID:(GTOID *)testOID
{
	if (!branchOID || !testOID)
		return NO;

	if ([testOID isEqual:branchOID])
		return YES;

	NSArray *revList = revisionList.projectCommits;

	NSMutableSet *searchOIDs = [NSMutableSet setWithObject:branchOID];

	for (PBGitCommit *commit in revList) {
		GTOID *commitOID = commit.OID;
		if ([searchOIDs containsObject:commitOID]) {
			if ([testOID isEqual:commitOID])
				return YES;
			[searchOIDs removeObject:commitOID];
			[searchOIDs addObjectsFromArray:commit.parents];
		}
		else if ([testOID isEqual:commitOID])
			return NO;
	}

	return NO;
}

- (BOOL)isOIDOnHeadBranch:(GTOID *)testOID
{
	if (!testOID)
		return NO;

	GTOID *headOID = self.headOID;

	if ([testOID isEqual:headOID])
		return YES;

	return [self isOIDOnSameBranch:headOID asOID:testOID];
}

- (BOOL)isRefOnHeadBranch:(PBGitRef *)testRef
{
	if (!testRef)
		return NO;

	return [self isOIDOnHeadBranch:[self OIDForRef:testRef]];
}

- (BOOL) checkRefFormat:(NSString *)refName
{
	BOOL result = [GTReference isValidReferenceName:refName];
	return result;
}

- (BOOL) refExists:(PBGitRef *)ref
{
	NSError *gtError = nil;
	GTReference *gtRef = [self.gtRepo lookUpReferenceWithName:ref.ref error:&gtError];
	if (gtRef) {
		return YES;
	}
	return NO;
}

// useful for getting the full ref for a user entered name
// EX:  name: master
//       ref: refs/heads/master
- (PBGitRef *)refForName:(NSString *)name
{
	if (!name)
		return nil;

	int retValue = 1;
    NSString *output = [self outputInWorkdirForArguments:[NSArray arrayWithObjects:@"show-ref", name, nil] retValue:&retValue];
	if (retValue)
		return nil;

	// the output is in the format: <SHA-1 ID> <space> <reference name>
	// with potentially multiple lines if there are multiple matching refs (ex: refs/remotes/origin/master)
	// here we only care about the first match
	NSArray *refList = [output componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([refList count] > 1) {
		NSString *refName = [refList objectAtIndex:1];
		return [PBGitRef refFromString:refName];
	}

	return nil;
}

- (NSArray*)branches
{
    return [self.branchesSet array];
}
		
// Returns either this object, or an existing, equal object
- (PBGitRevSpecifier*) addBranch:(PBGitRevSpecifier*)branch
{
	if ([[branch parameters] count] == 0)
		branch = [self headRef];

	// First check if the branch doesn't exist already
    if ([self.branchesSet containsObject:branch]) {
        return branch;
    }

	NSIndexSet *newIndex = [NSIndexSet indexSetWithIndex:[self.branches count]];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:newIndex forKey:@"branches"];

    [self.branchesSet addObject:branch];

	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:newIndex forKey:@"branches"];
	return branch;
}

- (BOOL) removeBranch:(PBGitRevSpecifier *)branch
{
    if ([self.branchesSet containsObject:branch]) {
        NSIndexSet *oldIndex = [NSIndexSet indexSetWithIndex:[self.branches indexOfObject:branch]];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:oldIndex forKey:@"branches"];

        [self.branchesSet removeObject:branch];

        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:oldIndex forKey:@"branches"];
        return YES;
    }
	return NO;
}
	
- (void) readCurrentBranch
{
		self.currentBranch = [self addBranch: [self headRef]];
}

- (void) setCurrentBranch:(PBGitRevSpecifier *)newCurrentBranch {
	currentBranch = newCurrentBranch;
	[revisionList updateHistory];
}

- (void) setCurrentBranchFilter:(NSInteger)newCurrentBranchFilter {
	currentBranchFilter = newCurrentBranchFilter;
	[revisionList updateHistory];
}

- (void) setHasChanged:(BOOL)newHasChanged {
	hasChanged = newHasChanged;
	[revisionList forceUpdate];
}


#pragma mark Stashes

- (NSArray *)stashes
{
	NSMutableArray *stashes = [NSMutableArray array];
	[self.gtRepo enumerateStashesUsingBlock:^(NSUInteger index, NSString *message, GTOID *oid, BOOL *stop) {
		PBGitStash *stash = [[PBGitStash alloc] initWithRepository:self stashOID:oid index:index message:message];
		[stashes addObject:stash];
	}];
    return [NSArray arrayWithArray:stashes];
}

- (PBGitStash *)stashForRef:(PBGitRef *)ref {
    __block PBGitStash * found = nil;

	[self.gtRepo enumerateStashesUsingBlock:^(NSUInteger index, NSString *message, GTOID *oid, BOOL *stop) {
		PBGitStash *stash = [[PBGitStash alloc] initWithRepository:self stashOID:oid index:index message:message];
        if ([stash.ref isEqualToRef:ref]) {
            found = stash;
            *stop = YES;
        }
	}];
    return found;
}

- (BOOL)stashRunCommand:(NSString *)command withStash:(PBGitStash *)stash
{
    int retValue;
    NSArray *arguments = @[@"stash", command, stash.ref.refishName];
	NSString *output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
    [self willChangeValueForKey:@"stashes"];
	[self didChangeValueForKey:@"stashes"];
	if (retValue) {
		NSString *title = [NSString stringWithFormat:@"Stash %@ failed!", command];
		NSString *message = [NSString stringWithFormat:@"There was an error!"];
		[self.windowController showErrorSheetTitle:title message:message arguments:arguments output:output];
    }
    return retValue ? NO : YES;
}

- (BOOL)stashPop:(PBGitStash *)stash
{
    return [self stashRunCommand:@"pop" withStash:stash];
}

- (BOOL)stashApply:(PBGitStash *)stash
{
    return [self stashRunCommand:@"apply" withStash:stash];
}

- (BOOL)stashDrop:(PBGitStash *)stash
{
    return [self stashRunCommand:@"drop" withStash:stash];
}

- (BOOL)stashSave
{
    return [self stashSaveWithKeepIndex:NO];
}

- (BOOL)stashSaveWithKeepIndex:(BOOL)keepIndex
{
    int retValue;
    NSArray * arguments = @[@"stash", @"save", keepIndex?@"--keep-index":@"--no-keep-index"];
    NSString * output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
    [self willChangeValueForKey:@"stashes"];
	[self didChangeValueForKey:@"stashes"];
    if (retValue) {
		NSString *title = [NSString stringWithFormat:@"Stash save failed!"];
		NSString *message = [NSString stringWithFormat:@"There was an error!"];
		[self.windowController showErrorSheetTitle:title message:message arguments:arguments output:output];
    }
    return retValue ? NO : YES;
}

- (BOOL)ignoreFilePaths:(NSArray *)filePaths error:(NSError **)error
{
	NSString *filesAsString = [filePaths componentsJoinedByString:@"\n"];

	// Write to the file
	NSString *gitIgnoreName = [self gitIgnoreFilename];

	NSStringEncoding enc = NSUTF8StringEncoding;
	NSString *ignoreFile;

	if (![[NSFileManager defaultManager] fileExistsAtPath:gitIgnoreName]) {
		ignoreFile = filesAsString;
	} else {
		NSMutableString *currentFile = [NSMutableString stringWithContentsOfFile:gitIgnoreName usedEncoding:&enc error:error];
		if (!currentFile) return NO;

		// Add a newline if not yet present
		if ([currentFile characterAtIndex:([ignoreFile length] - 1)] != '\n')
			[currentFile appendString:@"\n"];
		[currentFile appendString:filesAsString];

		ignoreFile = currentFile;
	}

	return [ignoreFile writeToFile:gitIgnoreName atomically:YES encoding:enc error:error];
}

- (PBGitIndex *)index
{
	if (!_index) {
		_index = [[PBGitIndex alloc] initWithRepository:self];
	}
	return _index;
}

#pragma mark Remotes

- (NSArray *) remotes
{
	int retValue = 1;
	NSString *remotes = [self outputInWorkdirForArguments:[NSArray arrayWithObject:@"remote"] retValue:&retValue];
	if (retValue || [remotes isEqualToString:@""])
		return nil;

	return [remotes componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (BOOL) hasRemotes
{
	return ([self remotes] != nil);
}

- (PBGitRef *) remoteRefForBranch:(PBGitRef *)branch error:(NSError **)error
{
	if ([branch isRemote]) {
		return [branch remoteRef];
	}

	NSError *gtError = nil;
	BOOL success = NO;
	NSAssert(branch.ref != nil, @"Unexpected nil ref");

	GTBranch *gtBranch = [self.gtRepo lookUpBranchWithName:branch.branchName type:GTBranchTypeLocal success:&success error:&gtError];
	if (!success) {
		NSString *failure = [NSString stringWithFormat:NSLocalizedString(@"There was an error looking up the branch \"%@\"", @""), branch.shortName];
		PBReturnError(error, NSLocalizedString(@"Branch lookup failed", @""), failure, gtError);
		return nil;
	}
	if (!gtBranch) {
		NSString *failure = [NSString stringWithFormat:NSLocalizedString(@"There doesn't seem to be a branch named \"%@\"", @""), branch.shortName];
		PBReturnError(error, NSLocalizedString(@"Branch lookup failed", @""), failure, gtError);
		return nil;
	}

	GTBranch *trackingBranch = [gtBranch trackingBranchWithError:&gtError success:&success];
	if (!success) {
		NSString *failure = [NSString stringWithFormat:NSLocalizedString(@"There was an error finding the tracking branch of branch \"%@\"", @""), branch.shortName];
		PBReturnError(error, NSLocalizedString(@"Branch lookup failed", @""), failure, gtError);
		return nil;
	}
	if (!trackingBranch) {
		PBReturnErrorWithBuilder(error, ^{
			NSString *info = [NSString stringWithFormat:@"There is no remote configured for branch \"%@\".", branch.shortName];
			NSString *recovery = NSLocalizedString(@"Please select a branch from the popup menu, which has a corresponding remote tracking branch set up.\n\nYou can also use a contextual menu to choose a branch by right clicking on its label in the commit history list.", @"");

			return [NSError pb_errorWithDescription:NSLocalizedString(@"No remote configured for branch", @"")
										failureReason:info
									  underlyingError:gtError
											 userInfo:@{NSLocalizedRecoverySuggestionErrorKey: recovery}];
		});
		return nil;
	}

	NSString *trackingBranchRefName = trackingBranch.reference.name;
	PBGitRef *trackingBranchRef = [PBGitRef refFromString:trackingBranchRefName];
	return trackingBranchRef;
}

- (NSString *) infoForRemote:(NSString *)remoteName
{
	int retValue = 1;
	NSString *output = [self outputInWorkdirForArguments:[NSArray arrayWithObjects:@"remote", @"show", remoteName, nil] retValue:&retValue];
	if (retValue)
		return nil;

	return output;
}

#pragma mark Repository commands

- (void) beginAddRemote:(NSString *)remoteName forURL:(NSString *)remoteURL
{
	NSArray *arguments = [NSArray arrayWithObjects:@"remote",  @"add", @"-f", remoteName, remoteURL, nil];

	NSString *description = [NSString stringWithFormat:@"Adding the remote %@ and fetching tracking branches", remoteName];
	NSString *title = @"Adding a remote";
	[PBRemoteProgressSheet beginRemoteProgressSheetWithTitle:title description:description arguments:arguments windowController:self.windowController];
}

- (void) beginFetchFromRemoteForRef:(PBGitRef *)ref
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"fetch"];

	NSString * remoteName;
	if (ref != nil) {
		if (![ref isRemote]) {
			NSError *error = nil;
			ref = [self remoteRefForBranch:ref error:&error];
			if (!ref) {
				if (error)
					[self.windowController showErrorSheet:error];
				return;
			}
		}
		remoteName = [ref remoteName];
		[arguments addObject:remoteName];
	}
	else {
		remoteName = @"all remotes";
		[arguments addObject:@"--all"];
	}
	
	NSString *description = [NSString stringWithFormat:@"Fetching all tracking branches for %@", remoteName];
	NSString *title = @"Fetching…";
	[PBRemoteProgressSheet beginRemoteProgressSheetWithTitle:title description:description arguments:arguments windowController:self.windowController];
}

- (void) beginPullFromRemote:(PBGitRef *)remoteRef forRef:(PBGitRef *)ref rebase:(BOOL)rebase
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"pull"];
	
	if (rebase) {
		[arguments addObject:@"--rebase"];
	}

	// a nil remoteRef means lookup the ref's default remote
	if (!remoteRef || ![remoteRef isRemote]) {
		NSError *error = nil;
		remoteRef = [self remoteRefForBranch:ref error:&error];
		if (!remoteRef) {
			if (error)
				[self.windowController showErrorSheet:error];
			return;
		}
	}
	NSString *remoteName = [remoteRef remoteName];
	[arguments addObject:remoteName];

	NSString *description = [NSString stringWithFormat:@"Pulling all tracking branches from %@", remoteName];
	NSString *title = @"Pulling from remote";
	[PBRemoteProgressSheet beginRemoteProgressSheetWithTitle:title description:description arguments:arguments hideSuccessScreen:YES windowController:self.windowController];
}

- (void) beginPushRef:(PBGitRef *)ref toRemote:(PBGitRef *)remoteRef
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"push"];

	// a nil remoteRef means lookup the ref's default remote
	if (!remoteRef || ![remoteRef isRemote]) {
		NSError *error = nil;
		remoteRef = [self remoteRefForBranch:ref error:&error];
		if (!remoteRef) {
			if (error)
				[self.windowController showErrorSheet:error];
			return;
		}
	}
	NSString *remoteName = [remoteRef remoteName];
	[arguments addObject:remoteName];

	NSString *branchName = nil;
	if ([ref isRemote] || !ref) {
		branchName = @"all updates";
	}
	else if ([ref isTag]) {
		branchName = [NSString stringWithFormat:@"tag '%@'", [ref tagName]];
		[arguments addObject:@"tag"];
		[arguments addObject:[ref tagName]];
	}
	else {
		branchName = [ref shortName];
		[arguments addObject:branchName];
	}

	NSString *description = [NSString stringWithFormat:@"Pushing %@ to %@", branchName, remoteName];
	NSString *title = @"Pushing to remote";
	[PBRemoteProgressSheet beginRemoteProgressSheetWithTitle:title description:description arguments:arguments hideSuccessScreen:true windowController:self.windowController];
}

- (BOOL) checkoutRefish:(id <PBGitRefish>)ref
{
	NSString *refName = nil;
	if ([ref refishType] == kGitXBranchType)
		refName = [ref shortName];
	else
		refName = [ref refishName];

	int retValue = 1;
	NSArray *arguments = [NSArray arrayWithObjects:@"checkout", refName, nil];
	NSString *output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *message = [NSString stringWithFormat:@"There was an error checking out the %@ '%@'.\n\nPerhaps your working directory is not clean?", [ref refishType], [ref shortName]];
		[self.windowController showErrorSheetTitle:@"Checkout failed!" message:message arguments:arguments output:output];
		return NO;
	}

	[self reloadRefs];
	[self readCurrentBranch];
	return YES;
}

- (BOOL) checkoutFiles:(NSArray *)files fromRefish:(id <PBGitRefish>)ref
{
	if (!files || ([files count] == 0))
		return NO;

	NSString *refName = nil;
	if ([ref refishType] == kGitXBranchType)
		refName = [ref shortName];
	else
		refName = [ref refishName];

	int retValue = 1;
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"checkout", refName, @"--", nil];
	[arguments addObjectsFromArray:files];
	NSString *output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *message = [NSString stringWithFormat:@"There was an error checking out the file(s) from the %@ '%@'.\n\nPerhaps your working directory is not clean?", [ref refishType], [ref shortName]];
		[self.windowController showErrorSheetTitle:@"Checkout failed!" message:message arguments:arguments output:output];
		return NO;
	}

	return YES;
}


- (BOOL) mergeWithRefish:(id <PBGitRefish>)ref
{
	NSString *refName = [ref refishName];

	int retValue = 1;
	NSArray *arguments = [NSArray arrayWithObjects:@"merge", refName, nil];
	NSString *output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *headName = [[[self headRef] ref] shortName];
		NSString *message = [NSString stringWithFormat:@"There was an error merging %@ into %@.", refName, headName];
		[self.windowController showErrorSheetTitle:@"Merge failed!" message:message arguments:arguments output:output];
		return NO;
	}

	[self reloadRefs];
	[self readCurrentBranch];
	return YES;
}

- (BOOL) cherryPickRefish:(id <PBGitRefish>)ref
{
	if (!ref)
		return NO;

	NSString *refName = [ref refishName];

	int retValue = 1;
	NSArray *arguments = [NSArray arrayWithObjects:@"cherry-pick", refName, nil];
	NSString *output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *message = [NSString stringWithFormat:@"There was an error cherry picking the %@ '%@'.\n\nPerhaps your working directory is not clean?", [ref refishType], [ref shortName]];
		[self.windowController showErrorSheetTitle:@"Cherry pick failed!" message:message arguments:arguments output:output];
		return NO;
	}

	[self reloadRefs];
	[self readCurrentBranch];
	return YES;
}

- (BOOL) rebaseBranch:(id <PBGitRefish>)branch onRefish:(id <PBGitRefish>)upstream
{
	if (!upstream)
		return NO;

	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"rebase", [upstream refishName], nil];

	if (branch)
		[arguments addObject:[branch refishName]];

	int retValue = 1;
	NSString *output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *branchName = @"HEAD";
		if (branch)
			branchName = [NSString stringWithFormat:@"%@ '%@'", [branch refishType], [branch shortName]];
		NSString *message = [NSString stringWithFormat:@"There was an error rebasing %@ with %@ '%@'.", branchName, [upstream refishType], [upstream shortName]];
		[self.windowController showErrorSheetTitle:@"Rebase failed!" message:message arguments:arguments output:output];
		return NO;
	}

	[self reloadRefs];
	[self readCurrentBranch];
	return YES;
}

- (BOOL) createBranch:(NSString *)branchName atRefish:(id <PBGitRefish>)ref
{
	if (!branchName || !ref)
		return NO;

	int retValue = 1;
	NSArray *arguments = [NSArray arrayWithObjects:@"branch", branchName, [ref refishName], nil];
	NSString *output = [self outputInWorkdirForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *message = [NSString stringWithFormat:@"There was an error creating the branch '%@' at %@ '%@'.", branchName, [ref refishType], [ref shortName]];
		[self.windowController showErrorSheetTitle:@"Create Branch failed!" message:message arguments:arguments output:output];
		return NO;
	}

	[self reloadRefs];
	return YES;
}

- (BOOL) createTag:(NSString *)tagName message:(NSString *)message atRefish:(id <PBGitRefish>)target
{
	if (!tagName)
		return NO;

	NSError *error = nil;

	GTObject *object = [self.gtRepo lookUpObjectByRevParse:[target refishName] error:&error];
	GTTag *newTag = nil;
	if (object && !error) {
		newTag = [self.gtRepo createTagNamed:tagName target:object tagger:self.gtRepo.userSignatureForNow message:message error:&error];
	}

	if (!newTag || error) {
		[self.windowController showErrorSheet:error];
		return NO;
	}

	[self reloadRefs];
	return YES;
}

- (BOOL) deleteRemote:(PBGitRef *)ref
{
	if (!ref || ([ref refishType] != kGitXRemoteType))
		return NO;

	int retValue = 1;
	NSArray *arguments = [NSArray arrayWithObjects:@"remote", @"rm", [ref remoteName], nil];
	NSString * output = [self outputForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *message = [NSString stringWithFormat:@"There was an error deleting the remote: %@\n\n", [ref remoteName]];
		[self.windowController showErrorSheetTitle:@"Delete remote failed!" message:message arguments:arguments output:output];
		return NO;
	}

	// remove the remote's branches
	NSString *remoteRef = [kGitXRemoteRefPrefix stringByAppendingString:[ref remoteName]];
	for (PBGitRevSpecifier *rev in [self.branchesSet copy]) {
		PBGitRef *branch = [rev ref];
		if ([[branch ref] hasPrefix:remoteRef]) {
			[self removeBranch:rev];
			PBGitCommit *commit = [self commitForRef:branch];
			[commit removeRef:branch];
		}
	}

	[self reloadRefs];
	return YES;
}

- (NSString *)performDiff:(PBGitCommit *)startCommit against:(PBGitCommit *)diffCommit forFiles:(NSArray *)filePaths {
	NSParameterAssert(startCommit);
	NSAssert(startCommit.repository == self, @"Different repo");

	if (diffCommit) {
		NSAssert(diffCommit.repository == self, @"Different repo");
	} else {
		diffCommit = [self headCommit];
	}

	NSString *commitSelector = [NSString stringWithFormat:@"%@..%@", startCommit.SHA, diffCommit.SHA];
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"diff", @"--no-ext-diff", commitSelector, nil];

	if (![PBGitDefaults showWhitespaceDifferences])
		[arguments insertObject:@"-w" atIndex:1];

	if (filePaths) {
		[arguments addObject:@"--"];
		[arguments addObjectsFromArray:filePaths];
	}

	int retValue;
	NSString *diff = [startCommit.repository outputInWorkdirForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSLog(@"diff failed with retValue: %d   for command: '%@'    output: '%@'", retValue, [arguments componentsJoinedByString:@" "], diff);
		return @"";
	}
	return diff;
}

- (BOOL) deleteRef:(PBGitRef *)ref
{
	if (!ref)
		return NO;

	if ([ref refishType] == kGitXRemoteType)
		return [self deleteRemote:ref];

	int retValue = 1;
	NSArray *arguments = [NSArray arrayWithObjects:@"update-ref", @"-d", [ref ref], nil];
	NSString * output = [self outputForArguments:arguments retValue:&retValue];
	if (retValue) {
		NSString *message = [NSString stringWithFormat:@"There was an error deleting the ref: %@\n\n", [ref shortName]];
		[self.windowController showErrorSheetTitle:@"Delete ref failed!" message:message arguments:arguments output:output];
		return NO;
	}

	[self removeBranch:[[PBGitRevSpecifier alloc] initWithRef:ref]];
	PBGitCommit *commit = [self commitForRef:ref];
	[commit removeRef:ref];

	[self reloadRefs];
	return YES;
}

- (BOOL)updateReference:(PBGitRef *)ref toPointAtCommit:(PBGitCommit *)newCommit {
	int retValue = 1;
	[self outputForArguments:@[@"update-ref", @"-mUpdate from GitX", ref.ref, newCommit.SHA] retValue:&retValue];
	return retValue != 0;
}

- (GTSubmodule *)submoduleAtPath:(NSString *)path error:(NSError **)error;
{
	NSString *standardizedPath = path.stringByStandardizingPath;
	for (GTSubmodule *submodule in self.submodules) {
		if ([standardizedPath hasSuffix:submodule.path]) {
			return submodule;
		}
	}
	if (error) {
		NSString *failure = [NSString stringWithFormat:@"The submodule at path \"%@\" couldn't be found.", path];
		*error = [NSError pb_errorWithDescription:@"Submodule not found" failureReason:failure];
	}
	return nil;
}

#pragma mark Hooks

- (BOOL)executeHook:(NSString *)name output:(NSString **)output {
	return [self executeHook:name withArgs:[NSArray array] output:output];
}

- (BOOL)executeHook:(NSString *)name withArgs:(NSArray *)arguments output:(NSString **)outputPtr {
	return [self executeHook:name arguments:arguments output:outputPtr error:NULL];
}

- (BOOL)executeHook:(NSString *)name error:(NSError **)error {
	return [self executeHook:name arguments:@[] error:error];
}

- (BOOL)executeHook:(NSString *)name arguments:(NSArray *)arguments error:(NSError **)error {
	return [self executeHook:name arguments:arguments output:NULL error:error];
}

- (BOOL)executeHook:(NSString *)name arguments:(NSArray *)arguments output:(NSString **)outputPtr error:(NSError **)error {
	NSParameterAssert(name != nil);

	NSString *hookPath = [[[[self gitURL] path] stringByAppendingPathComponent:@"hooks"] stringByAppendingPathComponent:name];
	if (![[NSFileManager defaultManager] isExecutableFileAtPath:hookPath]) {
		// XXX: Maybe return error ?
		return YES;
	}

	NSDictionary *info = @{
						   @"GIT_DIR": self.gitURL.path,
						   @"GIT_INDEX_FILE": [self.gitURL.path stringByAppendingPathComponent:@"index"],
						   };

	int ret = 1;
	NSString *output = [PBEasyPipe outputForCommand:hookPath withArgs:arguments inDir:[self workingDirectory] byExtendingEnvironment:info inputString:nil retValue:&ret];
	if (ret != 0) {
		NSString *failureReason = [NSString localizedStringWithFormat:@"Hook %@ failed", name];
		NSString *desc = nil;
		if (output.length == 0) {
			desc = [NSString localizedStringWithFormat:@"The %@ hook failed to run.", name];
		} else {
			desc = [NSString localizedStringWithFormat:@"The %@ hook failed to run and returned the following:\n%@", name, output];
		}

		if (error) *error = [NSError errorWithDomain:PBGitXErrorDomain
												code:0
											userInfo:@{
													   NSLocalizedFailureReasonErrorKey: failureReason,
													   NSLocalizedDescriptionKey: desc,
													   }
							 ];
	}

	if (outputPtr) *outputPtr = output;

	return (ret == 0);
}

- (BOOL)revisionExists:(NSString *)spec
{
	return [self.gtRepo lookUpObjectByRevParse:spec error:nil] != nil;
}

- (GTReference *)parseSymbolicReference:(NSString*) reference
{
	GTReference *gtRef = [self.gtRepo lookUpReferenceWithName:reference error:nil];
	if (!gtRef) return nil;
	id target = gtRef.unresolvedTarget;
	if ([target isKindOfClass:[GTReference class]]) {
		NSString *ref = ((GTReference *)target).name;
		if ([ref hasPrefix:@"refs/"]) return target;
	}
    return nil;
}

@end
