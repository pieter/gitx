//
//  PBGitRevList.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRevList.h"
#import "PBGitGrapher.h"

#import "PBRevPoolDelegate.h"

#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBGitRevSpecifier.h"
#import "PBGitRevPool.h"
#import "PBGitRepository.h"

#include "git/oid.h"
#include <ext/stdio_filebuf.h>
#include <iostream>
#include <string>
using namespace std;

@implementation PBGitRevList

@synthesize commits;
- initWithRepository:(PBGitRepository *)repo
{
	repository = repo;
	[repository addObserver:self forKeyPath:@"currentBranch" options:0 context:nil];

	return self;
}

- (void) reload
{
	[self readCommitsForce: YES];
}

- (void) readCommitsForce: (BOOL) force
{
	// We use refparse to get the commit sha that we will parse. That way,
	// we can check if the current branch is the same as the previous one
	// and in that case we don't have to reload the revision list.

	// If no branch is selected, don't do anything
	if (![repository currentBranch])
		return;

	PBGitRevSpecifier* newRev = [repository currentBranch];
	NSString* newSha = nil;

	if (!force && newRev && [newRev isSimpleRef]) {
		newSha = [repository parseReference:[newRev simpleRef]];
		if ([newSha isEqualToString:lastSha])
			return;
	}
	lastSha = newSha;

	NSThread * commitThread = [[NSThread alloc] initWithTarget: self selector: @selector(walkRevisionListWithSpecifier:) object:newRev];
	[commitThread start];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if (object == repository)
		[self readCommitsForce: NO];
}

- (void) walkRevisionListWithSpecifier:(PBGitRevSpecifier *)rev
{
	commits = [NSMutableArray array];
	grapher = [[PBGitGrapher alloc] initWithRepository:repository];
	PBGitRevPool *pool = [[PBGitRevPool alloc] initWithRepository:repository];
	pool.delegate = self;
	[pool loadRevisions:rev];
	[self linearizeCommits: pool];
	for (PBGitCommit *commit in commits)
		[grapher decorateCommit: commit];

	[self performSelectorOnMainThread:@selector(setCommits:) withObject:commits waitUntilDone:YES];
}


- (void)revPool:(PBGitRevPool *)pool encounteredCommit:(PBGitCommit *)commit
{
	[commits addObject: commit];
}

- (void)linearizeCommits:(PBGitRevPool *)pool
{
	NSDate *start = [NSDate date];

	/* Mark them and clear the indegree */
	for (PBGitCommit *commit in commits)
		commit.inDegree = 1;

	/* update the indegree */
	for (PBGitCommit *commit in commits)
	{
		int pNum;
		for (pNum = 0; pNum < commit.nParents; ++pNum) {
			PBGitCommit *parent = [pool commitWithOid:commit.parentShas[pNum]];
			if (parent.inDegree)
				parent.inDegree++;
		}
	}

	
	/*
	 * find the tips
	 *
	 * tips are nodes not reachable from any other node in the list
	 *
	 * the tips serve as a starting set for the work queue.
	 */
	NSMutableArray *tips = [NSMutableArray array];
	for (PBGitCommit *commit in commits)
	{
		if (commit.inDegree == 1)
			[tips insertObject:commit atIndex:0];
	}

	NSMutableArray *sortedCommits = [NSMutableArray array];
	while ([tips count])
	{
		PBGitCommit *commit = [tips lastObject];
		[tips removeLastObject];
		int pNum;
		int nParents = commit.nParents;
		for (pNum = 0; pNum < nParents; ++pNum) {
			PBGitCommit *parent = [pool commitWithOid:commit.parentShas[pNum]];
			if (!parent.inDegree)
				continue;
			
			/*
			 * parents are only enqueued for emission
			 * when all their children have been emitted thereby
			 * guaranteeing topological order.
			 */
			if (--parent.inDegree == 1)
				[tips addObject:parent];
		}
		/*
		 * current item is a commit all of whose children
		 * have already been emitted. we can emit it now.
		 */
		[sortedCommits addObject:commit];
	}

	commits = sortedCommits;
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Sorted %i commits in %f seconds", [commits count], duration);
}

@end
