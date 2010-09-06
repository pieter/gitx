//
//  PBGitRevList.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRevList.h"
#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBGitGrapher.h"
#import "PBGitRevSpecifier.h"

#include "git/oid.h"
#include <ext/stdio_filebuf.h>
#include <iostream>
#include <string>
#include <map>

using namespace std;


@interface PBGitRevList ()

@property (assign) BOOL isParsing;

@end


#define kRevListThreadKey @"thread"
#define kRevListRevisionsKey @"revisions"


@implementation PBGitRevList

@synthesize commits;
@synthesize isParsing;


- (id) initWithRepository:(PBGitRepository *)repo rev:(PBGitRevSpecifier *)rev shouldGraph:(BOOL)graph
{
	repository = repo;
	isGraphing = graph;
	currentRev = [rev copy];

	return self;
}


- (void) loadRevisons
{
	[parseThread cancel];

	parseThread = [[NSThread alloc] initWithTarget:self selector:@selector(walkRevisionListWithSpecifier:) object:currentRev];
	self.isParsing = YES;
	resetCommits = YES;
	[parseThread start];
}


- (void) finishedParsing
{
	self.isParsing = NO;
}


- (void) updateCommits:(NSDictionary *)update
{
	if ([update objectForKey:kRevListThreadKey] != parseThread)
		return;

	NSArray *revisions = [update objectForKey:kRevListRevisionsKey];
	if (!revisions || [revisions count] == 0)
		return;

	if (resetCommits) {
		self.commits = [NSMutableArray array];
		resetCommits = NO;
	}

	NSRange range = NSMakeRange([commits count], [revisions count]);
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];

	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"commits"];
	[commits addObjectsFromArray:revisions];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"commits"];
}


- (void) walkRevisionListWithSpecifier:(PBGitRevSpecifier*)rev
{
	NSDate *start = [NSDate date];
	NSMutableArray *revisions = [NSMutableArray array];
	PBGitGrapher *g = [[PBGitGrapher alloc] initWithRepository:repository];
	std::map<string, NSStringEncoding> encodingMap;
	NSThread *currentThread = [NSThread currentThread];

	NSString *formatString = @"--pretty=format:%H\01%e\01%an\01%s\01%P\01%at";
	BOOL showSign = [rev hasLeftRight];

	if (showSign)
		formatString = [formatString stringByAppendingString:@"\01%m"];
	
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"log", @"-z", @"--early-output", @"--topo-order", @"--children", formatString, nil];

	if (!rev)
		[arguments addObject:@"HEAD"];
	else
		[arguments addObjectsFromArray:[rev parameters]];

	NSString *directory = rev.workingDirectory ? [rev.workingDirectory path] : [[repository fileURL] path];
	NSTask *task = [PBEasyPipe taskForCommand:[PBGitBinary path] withArgs:arguments inDir:directory];
	[task launch];
	NSFileHandle* handle = [[task standardOutput] fileHandleForReading];
	
	int fd = [handle fileDescriptor];
	__gnu_cxx::stdio_filebuf<char> buf(fd, std::ios::in);
	std::istream stream(&buf);

	int num = 0;
	while (true) {
		string sha;
		if (!getline(stream, sha, '\1'))
			break;

		// We reached the end of some temporary output. Show what we have
		// until now, and then start again. The sha of the next thing is still
		// in this buffer. So, we use a substring of current input.
		if (sha[1] == 'i') // Matches 'Final output'
		{
			num = 0;
			if ([currentThread isCancelled])
				break;

			NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:currentThread, kRevListThreadKey, revisions, kRevListRevisionsKey, nil];
			[self performSelectorOnMainThread:@selector(updateCommits:) withObject:update waitUntilDone:NO];
			revisions = [NSMutableArray array];

			if (isGraphing)
				g = [[PBGitGrapher alloc] initWithRepository:repository];
			revisions = [NSMutableArray array];

			// If the length is < 40, then there are no commits.. quit now
			if (sha.length() < 40)
				break;

			sha = sha.substr(sha.length() - 40, 40);
		}

		// From now on, 1.2 seconds
		string encoding_str;
		getline(stream, encoding_str, '\1');
		NSStringEncoding encoding = NSUTF8StringEncoding;
		if (encoding_str.length())
		{
			if (encodingMap.find(encoding_str) != encodingMap.end()) {
				encoding = encodingMap[encoding_str];
			} else {
				encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[NSString stringWithUTF8String:encoding_str.c_str()]));
				encodingMap[encoding_str] = encoding;
			}
		}

		git_oid oid;
		git_oid_mkstr(&oid, sha.c_str());
		PBGitCommit* newCommit = [[PBGitCommit alloc] initWithRepository:repository andSha:oid];

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
			git_oid *parents = (git_oid *)malloc(sizeof(git_oid) * nParents);
			int parentIndex;
			for (parentIndex = 0; parentIndex < nParents; ++parentIndex)
				git_oid_mkstr(parents + parentIndex, parentString.substr(parentIndex * 41, 40).c_str());
			
			newCommit.parentShas = parents;
			newCommit.nParents = nParents;
		}

		int time;
		stream >> time;

		[newCommit setSubject:[NSString stringWithCString:subject.c_str() encoding:encoding]];
		[newCommit setAuthor:[NSString stringWithCString:author.c_str() encoding:encoding]];
		[newCommit setTimestamp:time];
		
		if (showSign)
		{
			char c;
			stream >> c; // Remove separator
			stream >> c;
			if (c != '>' && c != '<' && c != '^' && c != '-')
				NSLog(@"Error loading commits: sign not correct");
			[newCommit setSign: c];
		}

		char c;
		stream >> c;
		if (c != '\0')
			cout << "Error" << endl;

		[revisions addObject: newCommit];
		if (isGraphing)
			[g decorateCommit:newCommit];

		if (++num % 1000 == 0) {
			if ([currentThread isCancelled])
				break;
			NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:currentThread, kRevListThreadKey, revisions, kRevListRevisionsKey, nil];
			[self performSelectorOnMainThread:@selector(updateCommits:) withObject:update waitUntilDone:NO];
			revisions = [NSMutableArray array];
		}
	}
	
	if (![currentThread isCancelled]) {
		NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
		NSLog(@"Loaded %i commits in %f seconds", num, duration);

		// Make sure the commits are stored before exiting.
		NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:currentThread, kRevListThreadKey, revisions, kRevListRevisionsKey, nil];
		[self performSelectorOnMainThread:@selector(updateCommits:) withObject:update waitUntilDone:YES];

		[self performSelectorOnMainThread:@selector(finishedParsing) withObject:nil waitUntilDone:NO];
	}
	else {
		NSLog(@"[%@ %s] thread has been canceled", [self class], _cmd);
	}

	[task waitUntilExit];
}

@end
