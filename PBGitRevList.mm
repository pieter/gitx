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
	[self performSelectorOnMainThread:@selector(setCommits:) withObject:commits waitUntilDone:YES];
}


- (void)revPool:(PBGitRevPool *)pool encounteredCommit:(PBGitCommit *)commit
{
	[commits addObject: commit];
	[grapher decorateCommit: commit];
}

@end
