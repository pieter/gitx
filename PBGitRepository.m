//
//  PBGitRepository.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRepository.h"
#import "PBGitCommit.h"

#import "NSFileHandleExt.h"
#import "PBEasyPipe.h"

@implementation PBGitRepository

@synthesize path, revisionList;
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

+ (PBGitRepository*) repositoryWithPath:(NSString*) path
{

	PBGitRepository* repo = [[PBGitRepository alloc] initWithPath: path];
	return repo;
}

- (PBGitRepository*) initWithPath: (NSString*) p
{
	if ([p hasSuffix:@".git"])
		self.path = p;
	else {
		NSString* newPath = [PBEasyPipe outputForCommand:gitPath withArgs:[NSArray arrayWithObjects:@"rev-parse", @"--git-dir", nil] inDir:p];
		if ([newPath isEqualToString:@".git"])
			self.path = [p stringByAppendingPathComponent:@".git"];
		else
			self.path = newPath;
	}

	NSLog(@"Git path is: %@", self.path);
	revisionList = [[PBGitRevList alloc] initWithRepository:self andRevListParameters:[NSArray array]];
	return self;
}


- (NSFileHandle*) handleForArguments:(NSArray *)args
{
	NSString* gitDirArg = [@"--git-dir=" stringByAppendingString:path];
	NSMutableArray* arguments =  [NSMutableArray arrayWithObject: gitDirArg];
	[arguments addObjectsFromArray: args];
	return [PBEasyPipe handleForCommand:gitPath withArgs:arguments];
}

- (NSFileHandle*) handleForCommand:(NSString *)cmd
{
	NSArray* arguments = [cmd componentsSeparatedByString:@" "];
	return [self handleForArguments:arguments];
}

@end
