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
	[self walkRevisionListWithPBSpecifier:rev];
/*	if ([rev isSimpleRef]) {
		[self walkRevisionListWithSingleSpecifier:rev];
	} else {
		for (NSString *parameter in rev.parameters) {
			PBGitRevSpecifier *simpleRev = [[PBGitRevSpecifier alloc] initWithParameters:@[parameter]];
			[self walkRevisionListWithSingleSpecifier:simpleRev];
		}
	}
}

- (void) walkRevisionListWithSingleSpecifier:(PBGitRevSpecifier*)rev
{
	[self walkRevisionListWithPBSpecifier:rev];

	GTRepository *repo = self.repository.gtRepo;
	NSError *error = nil;
	if (rev.isSimpleRef) {
		NSString *refspec = rev.simpleRef;
		GTObject *object = [repo lookupObjectByRefspec:refspec error:&error];
		if ([object class] == [GTCommit class]) {
			GTCommit *commit = (GTCommit*)object;
			NSLog(@"Dug up commit: %@ {%@}", commit, commit.parents);
		}
	} else {
		if ([[rev.parameters objectAtIndex:0] isEqual:@"--branches"]) {
			NSArray *branches = [repo localBranchesWithError:&error];
			for (GTBranch *branch in branches) {
				[self walkBranch:branch];
			}
		}
	}
}

- (void) walkBranch:(GTBranch *)branch
{
	NSLog(@"Walking branch %@", branch.name);
	NSError *error = nil;
	GTCommit *commit = [branch targetCommitAndReturnError:&error];
	if (commit) {
		[self walkCommit:commit];
	} */
}

- (void) walkCommit:(GTCommit *)commit
{
	//
}

- (void) walkRevisionListWithPBSpecifier:(PBGitRevSpecifier*)rev
{
	@autoreleasepool {
		GTRepository *gtRepo = self.repository.gtRepo;
		NSDate *start = [NSDate date];
		NSDate *lastUpdate = [NSDate date];
		NSMutableArray *revisions = [NSMutableArray array];
		PBGitRepository *repo = self.repository;

		NSError *error = nil;
		
		PBGitGrapher *g = [[PBGitGrapher alloc] initWithRepository:repo];
		

		
		std::map<string, NSStringEncoding> encodingMap;
		NSThread *currentThread = [NSThread currentThread];
		
		NSString *formatString = @"--pretty=format:%H\03";

		NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"log",
									 @"-z",
									 @"--topo-order",
									 @"--children",
									 @"--encoding=UTF-8",
									 formatString, nil];
		
		if (!rev)
			[arguments addObject:@"HEAD"];
		else
			[arguments addObjectsFromArray:[rev parameters]];
		
		NSString *directory = rev.workingDirectory ? rev.workingDirectory.path : repo.fileURL.path;
		NSTask *task = [PBEasyPipe taskForCommand:[PBGitBinary path] withArgs:arguments inDir:directory];
		[task launch];
		NSFileHandle *handle = [task.standardOutput fileHandleForReading];
		
		int fd = [handle fileDescriptor];
		__gnu_cxx::stdio_filebuf<char> buf(fd, std::ios::in);
		std::istream stream(&buf);
		
		int num = 0;
		while (true) {
			if ([currentThread isCancelled])
				break;
			
			string sha;
			if (!getline(stream, sha, '\3'))
				break;
			
			
			git_oid oid;
			git_oid_fromstr(&oid, sha.c_str());

			PBGitCommit *newCommit = [[PBGitCommit alloc] initWithRepository:repo andCommit:oid];
			
			char c;
			stream >> c;
			if (c != '\0')
				cout << "Error" << endl;
			
			[revisions addObject: newCommit];
			if (self.isGraphing)
				[g decorateCommit:newCommit];
			
			if (++num % 100 == 0) {
				if ([[NSDate date] timeIntervalSinceDate:lastUpdate] > 0.1) {
					NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:currentThread, kRevListThreadKey, revisions, kRevListRevisionsKey, nil];
					[self performSelectorOnMainThread:@selector(updateCommits:) withObject:update waitUntilDone:NO];
					revisions = [NSMutableArray array];
					lastUpdate = [NSDate date];
				}
			}
		}
		
		if (![currentThread isCancelled]) {
			NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
			NSLog(@"Loaded %i commits in %f seconds (%f/sec)", num, duration, num/duration);
			
			// Make sure the commits are stored before exiting.
			NSDictionary *update = [NSDictionary dictionaryWithObjectsAndKeys:currentThread, kRevListThreadKey, revisions, kRevListRevisionsKey, nil];
			[self performSelectorOnMainThread:@selector(updateCommits:) withObject:update waitUntilDone:YES];
			
			[self performSelectorOnMainThread:@selector(finishedParsing) withObject:nil waitUntilDone:NO];
		}
		else {
			NSLog(@"[%@ %@] thread has been canceled", [self class], NSStringFromSelector(_cmd));
		}
		
		[task terminate];
		[task waitUntilExit];
	}
}

@end
