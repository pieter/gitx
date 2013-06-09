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
#import "PBEasyPipe.h"
#import "PBGitBinary.h"

#include <ObjectiveGit/ObjectiveGit.h>

#include <ext/stdio_filebuf.h>
#include <iostream>
#include <string>
#include <map>

using namespace std;


@interface PBGitRevList ()

@property (nonatomic, assign) BOOL isGraphing;
@property (nonatomic, assign) BOOL resetCommits;

@property (nonatomic, weak) PBGitRepository *repository;
@property (nonatomic, strong) PBGitRevSpecifier *currentRev;


@property (nonatomic, strong) NSThread *parseThread;

@end


#define kRevListThreadKey @"thread"
#define kRevListRevisionsKey @"revisions"


@implementation PBGitRevList

- (id) initWithRepository:(PBGitRepository *)repo rev:(PBGitRevSpecifier *)rev shouldGraph:(BOOL)graph
{
	self = [super init];
	if (!self) {
		return nil;
	}
	self.repository = repo;
	self.currentRev = [rev copy];
	self.isGraphing = graph;

	return self;
}


- (void) loadRevisons
{
	[self cancel];

	self.parseThread = [[NSThread alloc] initWithTarget:self selector:@selector(beginWalkWithSpecifier:) object:self.currentRev];
	self.isParsing = YES;
	self.resetCommits = YES;
	[self.parseThread start];
}


- (void)cancel
{
	[self.parseThread cancel];
	self.parseThread = nil;
	self.isParsing = NO;
}


- (void) finishedParsing
{
	self.parseThread = nil;
	self.isParsing = NO;
}


- (void) updateCommits:(NSDictionary *)update
{
	if ([update objectForKey:kRevListThreadKey] != self.parseThread)
		return;

	NSArray *revisions = [update objectForKey:kRevListRevisionsKey];
	if (!revisions || [revisions count] == 0)
		return;

	if (self.resetCommits) {
		self.commits = [NSMutableArray array];
		self.resetCommits = NO;
	}

	NSRange range = NSMakeRange([self.commits count], [revisions count]);
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];

	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"commits"];
	[self.commits addObjectsFromArray:revisions];
	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"commits"];
}

- (void) beginWalkWithSpecifier:(PBGitRevSpecifier*)rev
{
	// break the specifier down to components
//
	[self wproto:rev];
}

- (void) wproto:(PBGitRevSpecifier*)rev
{
	PBGitRepository *pbRepo = self.repository;
	GTRepository *repo = pbRepo.gtRepo;
	
	NSError *error = nil;
	GTEnumerator *enu = [[GTEnumerator alloc] initWithRepository:repo error:&error];

	[self setupEnumerator:enu forRevspec:rev];
	
	[self addCommitsFromEnumerator:enu inPBRepo:pbRepo];
}

- (void) setupEnumerator:(GTEnumerator*)enumerator
			  forRevspec:(PBGitRevSpecifier*)rev
{
	NSError *error = nil;
	GTRepository *repo = enumerator.repository;
	[enumerator resetWithOptions:GTEnumeratorOptionsTimeSort];
	if (rev.isSimpleRef) {
		GTObject *object = [repo lookupObjectByRefspec:rev.simpleRef error:&error];
		if ([object isKindOfClass:[GTCommit class]]) {
			[enumerator pushSHA:object.sha error:&error];
		}
	} else {
		for (NSString *param in rev.parameters) {
			if ([param isEqualToString:@"--branches"]) {
				NSArray *branches = [repo localBranchesWithError:&error];
				for (GTBranch *branch in branches) {
					[enumerator pushSHA:branch.sha error:&error];
				}
			}
			if ([param isEqualToString:@"--remotes"]) {
				NSArray *branches = [repo remoteBranchesWithError:&error];
				for (GTBranch *branch in branches) {
					[enumerator pushSHA:branch.sha error:&error];
				}
			}
		}
	}
}

- (void) addCommitsFromEnumerator:(GTEnumerator *)enumerator
						 inPBRepo:(PBGitRepository*)pbRepo;
{
	GTCommit *commit = nil;
	NSError *error = nil;
	GTRepository *repo = enumerator.repository;
	PBGitGrapher *g = [[PBGitGrapher alloc] initWithRepository:pbRepo];
	NSDate *lastUpdate = [NSDate date];
	NSThread *currentThread = [NSThread currentThread];
	
	int num = 0;
	NSMutableArray *revisions = [NSMutableArray array];
	do {
		commit = [enumerator nextObjectWithSuccess:nil error:&error];
		if (commit) {
			GTOID *oid = [[GTOID alloc] initWithSHA:commit.sha];
			PBGitCommit *newCommit = [[PBGitCommit alloc] initWithRepository:pbRepo andCommit:*oid.git_oid];
			
			[revisions addObject:newCommit];
			if (self.isGraphing) {
				[g decorateCommit:newCommit];
			}
			
			if (++num % 100 == 0) {
				if ([[NSDate date] timeIntervalSinceDate:lastUpdate] > 0.1) {
					NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:currentThread, kRevListThreadKey, revisions, kRevListRevisionsKey, nil];
					[self performSelectorOnMainThread:@selector(updateCommits:) withObject:update waitUntilDone:NO];
					revisions = [NSMutableArray array];
					lastUpdate = [NSDate date];
				}
			}
		}
	} while (commit);
	
	// Make sure the commits are stored before exiting.
	NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:currentThread, kRevListThreadKey, revisions, kRevListRevisionsKey, nil];
	[self performSelectorOnMainThread:@selector(updateCommits:) withObject:update waitUntilDone:YES];
	
	[self performSelectorOnMainThread:@selector(finishedParsing) withObject:nil waitUntilDone:NO];
}

@end
