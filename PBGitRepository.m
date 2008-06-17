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

@synthesize path, commits;
static NSString* gitPath = @"/usr/bin/env";

+ (PBGitRepository*) repositoryWithPath:(NSString*) path
{
	[self setGitPath];
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

	NSThread * commitThread = [[NSThread alloc] initWithTarget: self selector: @selector(initializeCommits) object:nil];
	[commitThread start];
	return self;
}


+ (void) setGitPath
{
	char* path = getenv("GIT_PATH");
	if (path != nil) {
		gitPath = [NSString stringWithCString:path];
		return;
	}
	
	// No explicit path. Try it with "which"
	gitPath = [PBEasyPipe outputForCommand:@"/usr/bin/which" withArgs:[NSArray arrayWithObject:@"git"]];

	if (gitPath.length == 0) {
		NSLog(@"Git path not found. Defaulting to /opt/pieter/bin/git");
		gitPath = @"/opt/pieter/bin/git";
	}
}

- (void) addCommit: (id) obj
{
	self.commits = [self.commits arrayByAddingObject:obj];
}

- (void) setCommits:(NSArray*) obj
{
	commits = obj;
}

- (void) initializeCommits
{
	
	NSMutableArray * newArray = [NSMutableArray array];
	NSDate* start = [NSDate date];
	NSFileHandle* handle = [self handleForCommand:@"log --pretty=format:%H\01%an\01%s\01%at HEAD"];

	int fd = [handle fileDescriptor];
	FILE* f = fdopen(fd, "r");
	char buffer[2050];
	buffer[2049] = 0;
	
	char* l;
	int num = 0;
	while (l = fgets(buffer, 2048, f)) {
		NSString* currentLine = [NSString stringWithCString:(const char *)l encoding:NSUTF8StringEncoding];
		if ([currentLine length] == 0)
			currentLine = [NSString stringWithCString:(const char *)l encoding:NSASCIIStringEncoding];
		NSArray* components = [currentLine componentsSeparatedByString:@"\01"];

		PBGitCommit* newCommit = [[PBGitCommit alloc] initWithRepository: self andSha: [components objectAtIndex:0]];
		newCommit.subject = [components objectAtIndex:2];
		newCommit.author = [components objectAtIndex:1];
		newCommit.date = [NSDate dateWithTimeIntervalSince1970:[[components objectAtIndex:3] intValue]];

		[newArray addObject: newCommit];
		num++;
		if (num % 10000 == 0)
			[self performSelectorOnMainThread:@selector(setCommits:) withObject:newArray waitUntilDone:NO];
	}

	[self performSelectorOnMainThread:@selector(setCommits:) withObject:newArray waitUntilDone:YES];
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);

	[NSThread exit];
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
