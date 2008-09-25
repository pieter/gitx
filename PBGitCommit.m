//
//  PBGitCommit.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitCommit.h"


@implementation PBGitCommit

@synthesize sha, repository, subject, author, date, parents, sign, lineInfo, refs;


- (NSString *) dateString
{
	NSDateFormatter* formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d %H:%M:%S" allowNaturalLanguage:NO];
	return [formatter stringFromDate: self.date];
}

- (NSArray*) treeContents
{
	return self.tree.children;
}

- initWithRepository:(PBGitRepository*) repo andSha:(NSString*) newSha
{
	details = nil;
	self.repository = repo;
	self.sha = newSha;
	return self;
}

- (NSString*) details
{
	if (details != nil)
		return details;

	NSFileHandle* handle = [self.repository handleForCommand:[@"show --pretty=raw " stringByAppendingString:self.sha]];
	details = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding: NSUTF8StringEncoding];

	return details;
}

- (NSString *) patch
{
	if (_patch != nil)
		return _patch;

	_patch = [repository outputForArguments:[NSArray arrayWithObjects:@"format-patch",  @"-1", @"--stdout", sha, nil]];
	return _patch;
}

- (PBGitTree*) tree
{
	return [PBGitTree rootForCommit: self];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}
@end
