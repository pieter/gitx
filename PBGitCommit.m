//
//  PBGitCommit.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitCommit.h"


@implementation PBGitCommit

@synthesize repository, subject, timestamp, author, parentShas, nParents, sign, lineInfo, refs;

- (NSArray *) parents
{
	if (nParents == 0)
		return NULL;

	int i;
	NSMutableArray *p = [NSMutableArray arrayWithCapacity:nParents];
	for (i = 0; i < nParents; ++i)
	{
		char *s = git_oid_mkhex(parentShas + i);
		[p addObject:[NSString stringWithUTF8String:s]];
		free(s);
	}
	return p;
}

- (NSDate *)date
{
	return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

- (NSString *) dateString
{
	NSDateFormatter* formatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d %H:%M:%S" allowNaturalLanguage:NO];
	return [formatter stringFromDate: self.date];
}

- (NSArray*) treeContents
{
	return self.tree.children;
}

- (git_oid *)sha
{
	return &sha;
}

- initWithRepository:(PBGitRepository*) repo andSha:(git_oid)newSha
{
	details = nil;
	repository = repo;
	sha = newSha;
	return self;
}

- (NSString *)realSha
{
	char *hex = git_oid_mkhex(&sha);
	NSString *str = [NSString stringWithUTF8String:hex];
	free(hex);
	return str;
}

// NOTE: This method should remain threadsafe, as we load it in async
// from the web view.
- (NSString*) details
{
	if (details != nil)
		return details;

	details = [self.repository outputForCommand:[@"show --pretty=raw " stringByAppendingString:[self realSha]]];
	
	return details;
}

- (NSString *) patch
{
	if (_patch != nil)
		return _patch;

	NSString *p = [repository outputForArguments:[NSArray arrayWithObjects:@"format-patch",  @"-1", @"--stdout", [self realSha], nil]];
	// Add a GitX identifier to the patch ;)
	_patch = [[p substringToIndex:[p length] -1] stringByAppendingString:@"+GitX"];
	return _patch;
}

- (PBGitTree*) tree
{
	return [PBGitTree rootForCommit: self];
}

- (void)addRef:(id)ref
{
	if (!self.refs)
		self.refs = [NSMutableArray arrayWithObject:ref];
	else
		[self.refs addObject:ref];
}

- (void)removeRef:(id)ref
{
	if (!self.refs)
		return;

	[refs removeObject:ref];
	if ([refs count] == 0)
		refs = NULL;
}

- (void)finalize
{
	free(parentShas);
	[super finalize];
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
	return NO;
}
@end
