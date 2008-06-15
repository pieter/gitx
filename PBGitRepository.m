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
	self.path = p;
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
	NSTask* task = [[NSTask alloc] init];
	task.launchPath = @"/usr/bin/which";
	task.arguments = [NSArray arrayWithObject:@"git"];
	NSPipe* pipe = [NSPipe pipe];
	NSFileHandle* handle = [pipe fileHandleForReading];
	task.standardOutput = pipe;
	[task launch];
	NSString* a = [handle readLine];
	gitPath = a;

	if (a.length == 0) {
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray * newArray = [NSMutableArray array];
	NSDate* start = [NSDate date];
	NSFileHandle* handle = [self handleForCommand:@"log --pretty=format:%H\01%s\01%an HEAD"];
	NSString* currentLine = [handle readLine];
	int num = 0;
	while (currentLine.length > 0) {
		NSArray* components = [currentLine componentsSeparatedByString:@"\01"];
		PBGitCommit* newCommit = [[PBGitCommit alloc] initWithRepository: self andSha: [components objectAtIndex:0]];
		newCommit.subject = [components objectAtIndex:1];
		newCommit.author = [components objectAtIndex:2];
		[newArray addObject: newCommit];
		num++;
		if (num % 1000 == 0)
			[self performSelectorOnMainThread:@selector(setCommits:) withObject:newArray waitUntilDone:NO];
		currentLine = [handle readLine];
	}

	[self performSelectorOnMainThread:@selector(setCommits:) withObject:newArray waitUntilDone:YES];
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);

	[pool release];
	[NSThread exit];
}

- (NSFileHandle*) handleForCommand:(NSString *)cmd
{
	NSString* gitDirArg = [@"--git-dir=" stringByAppendingString:path];
	NSArray* arguments =  [NSArray arrayWithObjects: gitDirArg, nil];
	arguments = [arguments arrayByAddingObjectsFromArray: [cmd componentsSeparatedByString:@" "]];
	
	NSTask* task = [[NSTask alloc] init];
	task.launchPath = gitPath;
	task.arguments = arguments;
	
	NSPipe* pipe = [NSPipe pipe];
	task.standardOutput = pipe;
	
	NSFileHandle* handle = [NSFileHandle fileHandleWithStandardOutput];
	handle = [pipe fileHandleForReading];
	
	[task launch];
	
	return handle;
}

@end
