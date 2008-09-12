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

@synthesize commits, grapher;
- initWithRepository: (id) repo andRevListParameters: (NSArray*) params
{
	parameters = params;
	repository = repo;

	[self readCommits];
	[repository addObserver:self forKeyPath:@"currentBranch" options:0 context:nil];

	return self;
}

- (void) readCommits
{
	// We use refparse to get the commit sha that we will parse. That way,
	// we can check if the current branch is the same as the previous one
	// and in that case we don't have to reload the revision list.

	// If no branch was selected, use the current HEAD
	PBGitRevSpecifier* newRev = [[[repository branches] objectsAtIndexes: [repository currentBranch]] objectAtIndex:0];
	NSString* newSha = nil;

	if (newRev && [newRev isSimpleRef])
		newSha = [repository parseReference:[newRev simpleRef]];

	if ([newSha isEqualToString:currentRef])
		return;

	currentRef = newSha;
	NSThread * commitThread = [[NSThread alloc] initWithTarget: self selector: @selector(walkRevisionListWithSpecifier:) object:newRev];
	[commitThread start];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if (object == repository)
		[self readCommits];
}

- (void) walkRevisionListWithSpecifier: (PBGitRevSpecifier*) rev
{
	
	NSMutableArray * newArray = [NSMutableArray array];
	NSDate* start = [NSDate date];
	NSMutableArray* arguments = [NSMutableArray arrayWithObjects:@"log", @"--topo-order", @"--pretty=format:%H\01%an\01%s\01%P\01%at", nil];
	if (!rev)
		[arguments addObject:@"HEAD"];
	else
		[arguments addObjectsFromArray:[rev parameters]];

	NSFileHandle* handle = [repository handleForArguments: arguments];
	
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
		
		[newArray addObject: newCommit];
		num++;
		if (num % 10000 == 0)
			[self performSelectorOnMainThread:@selector(setCommits:) withObject:newArray waitUntilDone:NO];
		currentLine = [NSMutableString string];
	}
	
	[self performSelectorOnMainThread:@selector(setCommits:) withObject:newArray waitUntilDone:YES];
	
	PBGitGrapher* g = [[PBGitGrapher alloc] initWithRepository: repository];
	[g parseCommits: self.commits];
	[self performSelectorOnMainThread:@selector(setGrapher:) withObject:g waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(setCommits:) withObject:newArray waitUntilDone:YES];
	
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);
	[NSThread exit];
}


@end
