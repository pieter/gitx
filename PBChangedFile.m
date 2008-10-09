//
//  PBChangedFile.m
//  GitX
//
//  Created by Pieter de Bie on 22-09-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBChangedFile.h"
#import "PBEasyPipe.h"

@implementation PBChangedFile

@synthesize path, status, hasCachedChanges, hasUnstagedChanges;

- (id) initWithPath:(NSString *)p andRepository:(PBGitRepository *)r
{
	path = p;
	repository = r;
	return self;
}

- (NSString *) cachedChangesAmend:(BOOL) amend
{
	if (amend)
		return [repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", @"--cached", @"HEAD^", @"--", path, nil]];

	return [repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", @"--cached", @"--", path, nil]];
}

- (NSString *)unstagedChanges
{
	if (status == NEW)
		return [PBEasyPipe outputForCommand:@"/bin/cat" withArgs:[NSArray arrayWithObject:path] inDir:[repository workingDirectory]];

	return [repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"diff", @"--", path, nil]];
}


- (NSImage *) icon
{
	NSString *filename;
	switch (status) {
		case NEW:
			filename = @"new_file";
			break;
		case DELETED:
			filename = @"deleted_file";
			break;
		default:
			filename = @"empty_file";
			break;
	}
	NSString *p = [[NSBundle mainBundle] pathForResource:filename ofType:@"png"];
	return [[NSImage alloc] initByReferencingFile: p];
}

- (void) stageChanges
{
	if (status == DELETED)
		[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"rm", path, nil]];
	else
		[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"add", path, nil]];

	self.hasUnstagedChanges = NO;
	self.hasCachedChanges = YES;
}

- (void) unstageChangesAmend:(BOOL) amend
{
	if (amend)
		[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"reset", @"HEAD^", @"--", path, nil]];
	else
		[repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"reset", @"--", path, nil]];
	self.hasCachedChanges = NO;
	self.hasUnstagedChanges = YES;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}

@end
