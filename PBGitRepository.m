//
//  PBGitRepository.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRepository.h"


@implementation PBGitRepository

static NSString* gitPath = @"/opt/pieter/bin/git";

+ (PBGitRepository*) repositoryWithPath:(NSString*) path
{
	PBGitRepository* repo = [[PBGitRepository alloc] init];
	repo.path = path;
	return repo;
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
	NSLog(@"Hey");
	if (commits != nil)
		return commits;
	
	NSFileHandle* handle = [self handleForCommand:@"rev-list HEAD"];
	
	int buffersize = 50;
	char buffer[buffersize];
	NSMutableArray * newArray = [NSMutableArray array];
	int fd = [handle fileDescriptor];
	FILE * file = fdopen(fd, "r");
	
	while (YES) {
		
		
		if (fgets(buffer, buffersize, file)) {
			NSString* s = [NSString stringWithCString:buffer length:buffersize];
			NSLog(@"Got string: %@", s);
			[newArray addObject:s];
		}
		else {
			fclose(file);
			NSLog(@"Done!");
			break;
		}
	}
	
	commits = newArray;
	return commits;
}

- (NSFileHandle*) handleForCommand:(NSString *)cmd
{
	NSString* gitDirArg = [@"--git-dir=" stringByAppendingString:path];
	NSArray* arguments =  [NSArray arrayWithObject:gitDirArg];
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
