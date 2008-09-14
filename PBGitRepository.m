//
//  PBGitRepository.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBDetailController.h"

#import "NSFileHandleExt.h"
#import "PBEasyPipe.h"
#import "PBGitRef.h"
#import "PBGitRevSpecifier.h"

NSString* PBGitRepositoryErrorDomain = @"GitXErrorDomain";

@implementation PBGitRepository

@synthesize revisionList, branches, currentBranch, refs;
static NSString* gitPath;

+ (void) initialize
{
	// Try to find the path of the Git binary
	char* path = getenv("GIT_PATH");
	if (path != nil) {
		gitPath = [NSString stringWithCString:path];
		return;
	}
	
	// No explicit path. Try it with "which"
	gitPath = [PBEasyPipe outputForCommand:@"/usr/bin/which" withArgs:[NSArray arrayWithObject:@"git"]];
	if (gitPath.length > 0)
		return;
	
	// Still no path. Let's try some default locations.
	NSArray* locations = [NSArray arrayWithObjects:@"/opt/local/bin/git", @"/sw/bin/git", @"/opt/git/bin/git", nil];
	for (NSString* location in locations) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:location]) {
			gitPath = location;
			return;
		}
	}
	
	NSLog(@"Could not find a git binary!");
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if (outError) {
		*outError = [NSError errorWithDomain:PBGitRepositoryErrorDomain
                                      code:0
                                  userInfo:[NSDictionary dictionaryWithObject:@"Reading files is not supported." forKey:NSLocalizedFailureReasonErrorKey]];
	}
	return NO;
}

+ (BOOL) isBareRepository: (NSString*) path
{
	return [[PBEasyPipe outputForCommand:gitPath withArgs:[NSArray arrayWithObjects:@"rev-parse", @"--is-bare-repository", nil] inDir:path] isEqualToString:@"true"];
}

+ (NSURL*)gitDirForURL:(NSURL*)repositoryURL;
{
	NSString* repositoryPath = [repositoryURL path];

	if ([self isBareRepository:repositoryPath])
		return repositoryURL;


	// Use rev-parse to find the .git dir for the repository being opened
	NSString* newPath = [PBEasyPipe outputForCommand:gitPath withArgs:[NSArray arrayWithObjects:@"rev-parse", @"--git-dir", nil] inDir:repositoryPath];
	if ([newPath isEqualToString:@".git"])
		return [NSURL fileURLWithPath:[repositoryPath stringByAppendingPathComponent:@".git"]];
	if ([newPath length] > 0)
		return [NSURL fileURLWithPath:newPath];

	return nil;
}

// For a given path inside a repository, return either the .git dir
// (for a bare repo) or the directory above the .git dir otherwise
+ (NSURL*)baseDirForURL:(NSURL*)repositoryURL;
{
	NSURL* gitDirURL         = [self gitDirForURL:repositoryURL];
	NSString* repositoryPath = [gitDirURL path];

	if (![self isBareRepository:repositoryPath]) {
		repositoryURL = [NSURL fileURLWithPath:[[repositoryURL path] stringByDeletingLastPathComponent]];
	}

	return repositoryURL;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError
{
	BOOL success = NO;

	if (![fileWrapper isDirectory]) {
		if (outError) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Reading files is not supported.", [fileWrapper filename]]
                                                              forKey:NSLocalizedRecoverySuggestionErrorKey];
			*outError = [NSError errorWithDomain:PBGitRepositoryErrorDomain code:0 userInfo:userInfo];
		}
	} else {
		NSURL* gitDirURL = [PBGitRepository gitDirForURL:[self fileURL]];
		if (gitDirURL) {
			[self setFileURL:gitDirURL];
			success = YES;
		} else if (outError) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ does not appear to be a git repository.", [fileWrapper filename]]
                                                              forKey:NSLocalizedRecoverySuggestionErrorKey];
			*outError = [NSError errorWithDomain:PBGitRepositoryErrorDomain code:0 userInfo:userInfo];
		}

		if (success) {
			[self readRefs];
			revisionList = [[PBGitRevList alloc] initWithRepository:self];
			[self readCurrentBranch];
		}
	}

	return success;
}

- (id) initWithURL: (NSURL*) path andRevSpecifier:(PBGitRevSpecifier*) rev
{
	self = [self init];
	NSURL* gitDirURL = [PBGitRepository gitDirForURL:path];
	[self setFileURL: gitDirURL];

	[self readRefs];

	revisionList = [[PBGitRevList alloc] initWithRepository:self];
	[self selectBranch: [self addBranch: rev]];

	return self;
}
// The fileURL the document keeps is to the .git dir, but that’s pretty
// useless for display in the window title bar, so we show the directory above
- (NSString*)displayName
{
	NSString* displayName = self.fileURL.path.lastPathComponent;
	if ([displayName isEqualToString:@".git"])
		displayName = [self.fileURL.path stringByDeletingLastPathComponent].lastPathComponent;
	return displayName;
}

// Overridden to create our custom window controller
- (void)makeWindowControllers
{
	PBDetailController* controller = [[PBDetailController alloc] initWithRepository:self];
	[self addWindowController:controller];
	[controller release];
}

- (void) readRefs
{
	NSString* output = [PBEasyPipe outputForCommand:gitPath withArgs:[NSArray arrayWithObjects:@"for-each-ref", @"--format=%(refname) %(objecttype) %(objectname) %(*objectname)", @"refs", nil] inDir: self.fileURL.path];
	NSArray* lines = [output componentsSeparatedByString:@"\n"];
	NSMutableDictionary* newRefs = [NSMutableDictionary dictionary];
	NSMutableArray* newBranches = [NSMutableArray array];
	for (NSString* line in lines) {
		NSArray* components = [line componentsSeparatedByString:@" "];
		PBGitRef* ref = [PBGitRef refFromString:[components objectAtIndex:0]];
		NSString* type = [components objectAtIndex:1];
		NSString* sha;
		if ([type isEqualToString:@"tag"] && [components count] == 4)
			sha = [components objectAtIndex:3];
		else
			sha = [components objectAtIndex:2];

		if ([[ref type] isEqualToString:@"head"] || [[ref type] isEqualToString:@"remote"])
			[newBranches addObject: [[PBGitRevSpecifier alloc] initWithRef:ref]];

		NSMutableArray* curRefs;
		if (curRefs = [newRefs objectForKey:sha])
			[curRefs addObject:ref];
		else
			[newRefs setObject:[NSMutableArray arrayWithObject:ref] forKey:sha];
	}
	self.refs = newRefs;
	self.branches = newBranches;
}

- (PBGitRevSpecifier*) headRef
{
	NSString* branch = [self parseSymbolicReference: @"HEAD"];
	if (branch && [branch hasPrefix:@"refs/heads/"])
		return [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:branch]];

	return [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:@"HEAD"]];
}
		
// Returns either this object, or an existing, equal object
- (PBGitRevSpecifier*) addBranch: (PBGitRevSpecifier*) rev
{
	if ([[rev parameters] count] == 0)
		rev = [self headRef];

	// First check if the branch doesn't exist already
	for (PBGitRevSpecifier* r in branches)
		if ([rev isEqualTo: r])
			return r;

	NSLog(@"Adding new branch");
	[branches addObject: rev];
	return rev;
}

- (void) selectBranch: (PBGitRevSpecifier*) rev
{
	int i;
	for (i = 0; i < [branches count]; i++) {
		PBGitRevSpecifier* aRev = [branches objectAtIndex:i];
		if (rev == aRev) {
			self.currentBranch = [NSIndexSet indexSetWithIndex:i];
			return;
		}
	}
}

- (void) readCurrentBranch
{
		[self selectBranch: [self addBranch: [self headRef]]];
}


- (NSFileHandle*) handleForArguments:(NSArray *)args
{
	NSString* gitDirArg = [@"--git-dir=" stringByAppendingString:self.fileURL.path];
	NSMutableArray* arguments =  [NSMutableArray arrayWithObject: gitDirArg];
	[arguments addObjectsFromArray: args];
	return [PBEasyPipe handleForCommand:gitPath withArgs:arguments];
}

- (NSFileHandle*) handleForCommand:(NSString *)cmd
{
	NSArray* arguments = [cmd componentsSeparatedByString:@" "];
	return [self handleForArguments:arguments];
}

- (NSString*) outputForCommand:(NSString *)cmd
{
	NSArray* arguments = [cmd componentsSeparatedByString:@" "];
	return [self outputForArguments: arguments];
}

- (NSString*) outputForArguments:(NSArray*) arguments
{
	return [PBEasyPipe outputForCommand:gitPath withArgs:arguments inDir: self.fileURL.path];
}

- (NSString*) parseReference:(NSString *)reference
{
	return [self outputForArguments:[NSArray arrayWithObjects: @"rev-parse", reference, nil]];
}

- (NSString*) parseSymbolicReference:(NSString*) reference
{
	NSString* ref = [self outputForArguments:[NSArray arrayWithObjects: @"symbolic-ref", reference, nil]];
	if ([ref hasPrefix:@"refs/"])
		return ref;

	return nil;
}
@end
