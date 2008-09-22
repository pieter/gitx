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

@synthesize files;

- (void)awakeFromNib
{
	[unstagedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"cached == 0"]];
	[cachedFilesController setFilterPredicate:[NSPredicate predicateWithFormat:@"cached == 1"]];
	[self refresh:self];
}

- (void) readOtherFiles
{
	NSArray *arguments = [NSArray arrayWithObjects:@"ls-files", @"--others", @"--exclude-standard", nil];
	NSFileHandle *handle = [repository handleInWorkDirForArguments:arguments];
	
	NSString *line;
	while (line = [handle readLine]) {
		if ([line length] == 0)
			break;
		PBChangedFile *file =[[PBChangedFile alloc] initWithPath:line andRepository:repository];
		file.status = NEW;
		file.cached = NO;
		[files addObject: file];
	}
}

- (void) refresh:(id) sender
{
	files = [NSMutableArray array];
	[self readUnstagedFiles];
	[self readCachedFiles];
	[self readOtherFiles];
	self.files = files;
}

- (void) readUnstagedFiles
{
	NSFileHandle *handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObject:@"diff-files"]];
		
	NSString *line;
	while (line = [handle readLine]) {
		NSArray *components = [line componentsSeparatedByString:@"\t"];
		if ([components count] < 2)
			break;
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:[components objectAtIndex:1] andRepository:repository];
		file.status = MODIFIED;
		file.cached =NO;
		[files addObject: file];
	}
}

- (void) readCachedFiles
{
	NSFileHandle *handle = [repository handleInWorkDirForArguments:[NSArray arrayWithObjects:@"diff-index", @"--cached", @"HEAD", nil]];
	
	NSString *line;
	while (line = [handle readLine]) {
		NSArray *components = [line componentsSeparatedByString:@"\t"];
		if ([components count] < 2)
			break;
		PBChangedFile *file = [[PBChangedFile alloc] initWithPath:[components objectAtIndex:1] andRepository:repository];
		file.status = MODIFIED;
		file.cached = YES;
		[files addObject: file];
	}
}

- (void) cellClicked:(id) sender
{
	NSLog(@"Cell clicked: %@", sender);
}

@end
