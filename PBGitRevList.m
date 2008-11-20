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

- (void) walkRevisionListWithSpecifier: (PBGitRevSpecifier*) rev
{
	NSDate *start = [NSDate date];
	NSMutableArray* revisions = [NSMutableArray array];
	PBGitGrapher* g = [[PBGitGrapher alloc] initWithRepository: repository];
	NSDictionary* refs = [repository refs];

	NSMutableArray* arguments;
	BOOL showSign = [rev hasLeftRight];

	if (showSign)
		arguments = [NSMutableArray arrayWithObjects:@"log", @"--early-output", @"--topo-order", @"--pretty=format:%H\01%an\01%s\01%P\01%at\01%m", nil];
	else
		arguments = [NSMutableArray arrayWithObjects:@"log", @"--early-output", @"--topo-order", @"--pretty=format:%H\01%an\01%s\01%P\01%at", nil];

	if (!rev)
		[arguments addObject:@"HEAD"];
	else
		[arguments addObjectsFromArray:[rev parameters]];

	if ([rev hasPathLimiter])
		[arguments insertObject:@"--children" atIndex:1];

	NSTask *task = [PBEasyPipe taskForCommand:[PBGitBinary path] withArgs:arguments inDir:[repository fileURL].path];
	[task launch];
	NSFileHandle* handle = [task.standardOutput fileHandleForReading];
	
	int fd = [handle fileDescriptor];
	FILE* f = fdopen(fd, "r");
	int BUFFERSIZE = 2048;
	char buffer[BUFFERSIZE];
	buffer[BUFFERSIZE - 2] = 0;
	
	char* l;
	int num = 0;
	NSMutableString* currentLine = [NSMutableString string];
	while (l = fgets(buffer, BUFFERSIZE, f)) {
		NSString *s = [NSString stringWithCString:(const char *)l encoding:NSUTF8StringEncoding];
		if ([s length] == 0)
			s = [NSString stringWithCString:(const char *)l encoding:NSASCIIStringEncoding];
		[currentLine appendString: s];
		
		// If buffer is full, we go for another round
		if (buffer[BUFFERSIZE - 2] != 0) {
			buffer[BUFFERSIZE - 2] = 0;
			continue;
		}

		// We reached the end of some temporary output. Show what we have
		// until now, and then start from the beginning.
		if ([currentLine hasPrefix:@"Final output:"]) {
			[self performSelectorOnMainThread:@selector(setCommits:) withObject:revisions waitUntilDone:NO];
			g = [[PBGitGrapher alloc] initWithRepository: repository];
			revisions = [NSMutableArray array];
			[currentLine setString: @""];
			continue;
		}

		// If we are here, we currentLine is a full line.
		NSArray* components = [currentLine componentsSeparatedByString:@"\01"];
		if ([components count] < 5) {
			NSLog(@"Can't split string: %@", currentLine);
			[currentLine setString: @""];
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

		[revisions addObject: newCommit];
		[g decorateCommit: newCommit];
		
		if (refs && [refs objectForKey:newCommit.sha])
			newCommit.refs = [refs objectForKey:newCommit.sha];
		
		if (++num % 1000 == 0)
			[self performSelectorOnMainThread:@selector(setCommits:) withObject:revisions waitUntilDone:NO];

	
		[currentLine setString: @""];
	}
	
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);
	// Make sure the commits are stored before exiting.
	[self performSelectorOnMainThread:@selector(setCommits:) withObject:revisions waitUntilDone:YES];
	[task waitUntilExit];
}

@end
