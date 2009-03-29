//
//  PBGitRevPool.m
//  GitX
//
//  Created by Pieter de Bie on 29-03-09.
//  Copyright 2009 Pieter de Bie. All rights reserved.
//

#import "PBGitRevSpecifier.h"
#import "PBGitRevPool.h"
#import "PBGitCommit.h"
#import "PBGitRepository.h"
#import "PBEasyPipe.h"
#import "PBGitBinary.h"
#import "PBRevPoolDelegate.h"

#include "git/oid.h"
#include <ext/stdio_filebuf.h>
#include <iostream>
#include <string>

using namespace std;

@implementation PBGitRevPool

@synthesize delegate;

NSUInteger git_oid_size(const void *item)
{
	git_oid *oid = (git_oid *)item;
	return sizeof(*oid);
}

- initWithRepository:(PBGitRepository *)repo
{
	if (![super init])
		return nil;

	repository = repo;
	NSPointerFunctions *keyFunctions = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsOpaqueMemory|NSPointerFunctionsStructPersonality];
	keyFunctions.sizeFunction = git_oid_size;
	NSPointerFunctions *valueFunction = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality];
	revisions = [[NSMapTable alloc] initWithKeyPointerFunctions:keyFunctions valuePointerFunctions:valueFunction capacity:100];
	return self;
}

- (void)loadRevisions:(PBGitRevSpecifier *)rev
{
	NSDate *start = [NSDate date];

	NSMutableArray* arguments = [NSMutableArray arrayWithObjects:@"log", @"-z", @"--pretty=format:%H\01%an\01%s\01%P\01%at", nil];

	if (!rev)
		[arguments addObject:@"HEAD"];
	else
		[arguments addObjectsFromArray:[rev parameters]];

	NSTask *task = [PBEasyPipe taskForCommand:[PBGitBinary path] withArgs:arguments inDir:[repository fileURL].path];
	[task launch];
	NSFileHandle *handle = [task.standardOutput fileHandleForReading];
	int fd = [handle fileDescriptor];
	__gnu_cxx::stdio_filebuf<char> buf(fd, std::ios::in);
	std::istream stream(&buf);

	int num = 0;
	while (true) {
		string sha;
		if (!getline(stream, sha, '\1'))
			break;

		// From now on, 1.2 seconds
		git_oid *oid = (git_oid *)malloc(sizeof(git_oid));
		CFRetain(oid);
		git_oid_mkstr(oid, sha.c_str());
		PBGitCommit *newCommit = [[PBGitCommit alloc] initWithRepository:repository andSha:oid];
		
		string author;
		getline(stream, author, '\1');
		
		string subject;
		getline(stream, subject, '\1');
		
		string parentString;
		getline(stream, parentString, '\1');
		if (parentString.size() != 0)
		{
			if (((parentString.size() + 1) % 41) != 0) {
				NSLog(@"invalid parents: %i", parentString.size());
				continue;
			}
			int nParents = (parentString.size() + 1) / 41;
			git_oid **parents = (git_oid **)malloc(sizeof(git_oid *) * nParents);
			int parentIndex;
			for (parentIndex = 0; parentIndex < nParents; ++parentIndex) {
				git_oid *p_id = (git_oid *)malloc(sizeof(git_oid));
				git_oid_mkstr(p_id, parentString.substr(parentIndex * 41, 40).c_str());
				git_oid *existingKey;
				void *a;
				if (NSMapMember(revisions, p_id, (void **)&existingKey, &a))
				{
					parents[parentIndex] = existingKey;
					free(p_id);
				} else {
					NSMapInsertKnownAbsent(revisions, p_id, NULL);
					parents[parentIndex] = p_id;
				}

				//NSLog(@"Parent: %i", parents[parentIndex]);
				
			}

			newCommit.parentShas = parents;
			newCommit.nParents = nParents;
		}
		
		int time;
		stream >> time;
		
		
		[newCommit setSubject:[NSString stringWithUTF8String:subject.c_str()]];
		[newCommit setAuthor:[NSString stringWithUTF8String:author.c_str()]];
		[newCommit setTimestamp:time];

		char c;
		stream >> c;
		if (c != '\0')
			cout << "Error" << endl;

		++num;
		NSMapInsert(revisions, oid, newCommit);
		if (delegate)
			[delegate revPool:self encounteredCommit:newCommit];
	}

	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);

	[task waitUntilExit];	
}

- (void)listCommits
{
	NSEnumerator *enumerator = [revisions objectEnumerator];
	id value;
	int i = 0;
	while ((value = [enumerator nextObject])) {
		i++;
		NSLog(@"Commit: %@", [value realSha]);
	}
}

- (PBGitCommit *)commitWithSha:(NSString *)sha
{
	git_oid oid;
	git_oid_mkstr(&oid, [sha UTF8String]);
	return (PBGitCommit *)NSMapGet(revisions, &oid);
}

- (PBGitCommit *)commitWithOid:(git_oid *)oid
{
	NSAssert(oid, @"We need a parent");

	return (PBGitCommit *)NSMapGet(revisions, oid);
}
@end
