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

@implementation PBGitRevList

@synthesize commits;
- initWithRepository: (id) repo andRevListParameters: (NSArray*) params
{
	parameters = params;
	repository = repo;
	NSThread * commitThread = [[NSThread alloc] initWithTarget: self selector: @selector(walkRevisionList) object:nil];
	[commitThread start];
	return self;
}

- (void) walkRevisionList
{
	
	NSMutableArray * newArray = [NSMutableArray array];
	NSDate* start = [NSDate date];
	NSFileHandle* handle = [repository handleForCommand:@"log --pretty=format:%H\01%an\01%s\01%P\01%at HEAD"];
	
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
	NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	NSLog(@"Loaded %i commits in %f seconds", num, duration);
	
	[NSThread exit];
}

@end
