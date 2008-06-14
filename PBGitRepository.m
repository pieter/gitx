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

static NSString* gitPath = @"/usr/bin/env";

+ (PBGitRepository*) repositoryWithPath:(NSString*) path
{
	[self setGitPath];
	PBGitRepository* repo = [[PBGitRepository alloc] init];
	repo.path = path;
	return repo;
}

+ (void) setGitPath
{
	char* path = getenv("GIT_PATH");
	if (path != nil) {
		gitPath = [NSString stringWithCString:path];
		NSLog(@"Git path is now '%@'", gitPath);
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
	NSLog(@"Git path is now '%@'", gitPath);

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

- (NSArray*) commits
{
	if (commits != nil)
		return commits;
	
	NSFileHandle* handle = [self handleForCommand:@"log --pretty=format:%H%x01%s%x01%an HEAD"];
	NSMutableArray * newArray = [NSMutableArray array];
	NSString* currentLine = [handle readLine];

	while (currentLine.length > 0) {
		NSArray* components = [currentLine componentsSeparatedByString:@"\01"];
		PBGitCommit* newCommit = [[PBGitCommit alloc] initWithRepository: self andSha: [components objectAtIndex:0]];
		newCommit.subject = [components objectAtIndex:1];
		newCommit.author = [components objectAtIndex:2];
		[newArray addObject: newCommit];
		currentLine = [handle readLine];
	}

	commits = newArray;
	return commits;
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

@synthesize path;

@end
