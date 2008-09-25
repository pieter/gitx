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

@implementation PBGitRevList

@synthesize commits;
- initWithRepository: (id) repo
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
	if (![repository currentBranch] || [[repository currentBranch] count] == 0)
		return;

	NSArray* selectedBranches = [[repository branches] objectsAtIndexes: [repository currentBranch]];

	// Apparently, The selected index does not exist.. don't do anything
	if ([selectedBranches count] == 0)
		return;

	PBGitRevSpecifier* newRev = [selectedBranches objectAtIndex:0];
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

struct decorateParameters {
	NSMutableArray* revisions;
	PBGitRevSpecifier* rev;
};

- (void) walkRevisionListWithSpecifier: (PBGitRevSpecifier*) rev
{
	
	NSMutableArray* newArray = [NSMutableArray array];
	NSMutableArray* arguments;
	BOOL showSign = [rev hasLeftRight];

	if (showSign)
		arguments = [NSMutableArray arrayWithObjects:@"log", @"--topo-order", @"--pretty=format:%H\01%an\01%s\01%P\01%at\01%m", nil];
	else
		arguments = [NSMutableArray arrayWithObjects:@"log", @"--topo-order", @"--pretty=format:%H\01%an\01%s\01%P\01%at", nil];

	if (!rev)
		[arguments addObject:@"HEAD"];
	else
		[arguments addObjectsFromArray:[rev parameters]];

	if ([rev hasPathLimiter])
		[arguments insertObject:@"--children" atIndex:1];

	NSFileHandle* handle = [repository handleForArguments: arguments];
	
	// We decorate the commits in a separate thread.
	NSThread * decorationThread = [[NSThread alloc] initWithTarget: self selector: @selector(decorateRevisions:) object:newArray];
	[decorationThread start];

	int fd = [handle fileDescriptor];
	FILE* f = fdopen(fd, "r");
	int BUFFERSIZE = 2048;
	char buffer[BUFFERSIZE];
	buffer[BUFFERSIZE - 2] = 0;
	
	char* l;

	NSMutableString* currentLine = [NSMutableString string];
	while (l = fgets(buffer, BUFFERSIZE, f)) {
		NSString *s = [NSString stringWithCString:(const char *)l encoding:NSUTF8StringEncoding];
		if ([s length] == 0)
			s = [NSString stringWithCString:(const char *)l encoding:NSASCIIStringEncoding];
		[currentLine appendString: s];
		
		// If buffer is full, we go for another round
		if (buffer[BUFFERSIZE - 2] != 0) {
			//NSLog(@"Line too long!");
			buffer[BUFFERSIZE - 2] = 0;
			continue;
		}
		
		// If we are here, we currentLine is a full line.
		NSArray* components = [currentLine componentsSeparatedByString:@"\01"];
		if ([components count] < 5) {
			NSLog(@"Can't split string: %@", currentLine);
			continue;
		}
		PBGitCommit* newCommit = [[PBGitCommit alloc] initWithRepository: repository andSha: [components objectAtIndex:0]];
		NSArray* parents = [[components objectAtIndex:3] componentsSeparatedByString:@" "];
		newCommit.parents = parents;
		newCommit.subject = [components objectAtIndex:2];
		newCommit.author = [components objectAtIndex:1];
		newCommit.date = [NSDate dateWithTimeIntervalSince1970:[[components objectAtIndex:4] intValue]];
		if (showSign)
			newCommit.sign = [[components objectAtIndex:5] characterAtIndex:0];

		@synchronized(newArray) {
			[newArray addObject: newCommit];
		}
		currentLine = [NSMutableString string];
	}
	
	[decorationThread cancel];
	
	[NSThread exit];
}

- (void) decorateRevisions:(NSMutableArray *)revisions
{
	NSDictionary* refs = [repository refs];

	NSDate* start = [NSDate date];

	NSMutableArray* allRevisions = [NSMutableArray arrayWithCapacity:1000];
	int num = 0;

	PBGitGrapher* g = [[PBGitGrapher alloc] initWithRepository: repository];

	while (!([[NSThread currentThread] isCancelled] && [revisions count] == 0)) {
		if ([revisions count] == 0)
			usleep(5000);

		NSArray* currentRevisions;
		@synchronized(revisions) {
			currentRevisions = [revisions copy];
			[revisions removeAllObjects];
		}
		for (PBGitCommit* commit in currentRevisions) {
			num++;
			[g decorateCommit: commit];

			if (refs && [refs objectForKey:commit.sha])
				commit.refs = [refs objectForKey:commit.sha];

			[allRevisions addObject: commit];
			if (num % 1000 == 0 || num == 10)
				[self performSelectorOnMainThread:@selector(setCommits:) withObject:allRevisions waitUntilDone:NO];
		}
	}

	[self performSelectorOnMainThread:@selector(setCommits:) withObject:allRevisions waitUntilDone:YES];
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);

	[NSThread exit];
}

@end
