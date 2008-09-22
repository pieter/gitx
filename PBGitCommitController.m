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

@implementation PBGitCommitController

@synthesize unstagedFiles, cachedFiles;

- (void)awakeFromNib
{
	[self readUnstagedFiles];
	[self readCachedFiles];
	[self readOtherFiles];
}

- (void) readOtherFiles
{
	NSArray *arguments = [NSArray arrayWithObjects:@"ls-files", @"--others", @"--exclude-standard", nil];
	NSFileHandle *handle = [repository handleInWorkDirForArguments:arguments];
	
	NSString *line;
	NSMutableArray *files = [NSMutableArray array];
	while (line = [handle readLine]) {
		if ([line length] == 0)
			break;
		PBChangedFile *file =[[PBChangedFile alloc] initWithPath:line andRepository:repository];
		file.status = NEW;
		[files addObject: file];
	}
	self.unstagedFiles = [self.unstagedFiles arrayByAddingObjectsFromArray:files];
}

- (void) readUnstagedFiles
{
	NSFileHandle *handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObject:@"diff-files"]];
		
	NSString *line;
	NSMutableArray *files = [NSMutableArray array];
	while (line = [handle readLine]) {
		NSArray *components = [line componentsSeparatedByString:@"\t"];
		if ([components count] < 2)
			break;
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:[components objectAtIndex:1] andRepository:repository];
		file.status = MODIFIED;
		[files addObject: file];
	}
	self.unstagedFiles = files;
}

- (void) readCachedFiles
{
	NSFileHandle *handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObjects:@"diff-index", @"--cached", @"HEAD", nil]];
	
	NSString *line;
	NSMutableArray *files = [NSMutableArray array];
	while (line = [handle readLine]) {
		NSArray *components = [line componentsSeparatedByString:@"\t"];
		if ([components count] < 2)
			break;
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:[components objectAtIndex:1] andRepository:repository];
		file.status = MODIFIED;
		[files addObject: file];
	}
	self.cachedFiles = files;
}


@end
