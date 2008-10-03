//
//  PBGitGrapher.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitGrapher.h"
#import "PBGitCommit.h"
#import "PBGitLane.h"

@implementation PBGitGrapher

- (id) initWithRepository: (PBGitRepository*) repo
{
	refs = repo.refs;
	repository = repo;
	previousLanes = [NSMutableArray array];
	[PBGitLane resetColors];

	return self;
}

- (void) decorateCommit: (PBGitCommit *) commit
{
	int i = 0, newPos = -1;
	NSMutableArray* currentLanes = [NSMutableArray array];
	NSMutableArray* lines = [NSMutableArray array];
	PBGitLane* currentLane = NULL;
	BOOL didFirst = NO;

	// First, iterate over earlier columns and pass through any that don't want this commit
	if (previous != nil) {

		// We can't count until numColumns here, as it's only used for the width of the cell.
		for (PBGitLane* lane in previousLanes) {
			i++;
			// This is our commit! We should do a "merge": move the line from
			// our upperMapping to their lowerMapping
			if ([lane isCommit:commit.sha]) {
				if (!didFirst) {
					didFirst = YES;
					currentLane = lane;
					[currentLanes addObject: lane];
					newPos = [currentLanes count];
				}
				[lines addObject: [PBGitGraphLine upperLineFrom: i to: newPos color: [lane index]]];
			}
			else {
				// We are not this commit.
				// Try to find an earlier column for this commit.
				int j = 0;
				BOOL found = NO;
				for (PBGitLane* column in currentLanes) {
					j++;
					// ??? what is this?
//						if (j == newPos)
//							continue;
					if ([lane isCommit: commit.sha]) {
						// We already have a column for this commit. use it instead
						[lines addObject: [PBGitGraphLine upperLineFrom: i to: j color: [lane index]]];
						found = YES;
						break;
					}
				}

				// We need a new column for this.
				if (!found) {

					[currentLanes addObject: lane];
					[lines addObject: [PBGitGraphLine upperLineFrom: i to: [currentLanes count] color: [lane index]]];
					[lines addObject: [PBGitGraphLine lowerLineFrom: [currentLanes count] to: [currentLanes count] color: [lane index]]];
				}
			}
			// For existing columns, we always just continue straight down
			// ^^ I don't know what that means anymore :(
			[lines addObject:[PBGitGraphLine lowerLineFrom:newPos to:newPos color: [currentLane index]]];
		}
	}

	//Add your own parents

	// If we already did the first parent, don't do so again
	if (!didFirst) {
		PBGitLane* newLane = [[PBGitLane alloc] initWithCommit:[commit.parents objectAtIndex:0]];
		[currentLanes addObject: newLane];
		newPos = [currentLanes count];
		[lines addObject:[PBGitGraphLine lowerLineFrom: newPos to: newPos color: [newLane index]]];
	}

	// Add all other parents

	// If we add at least one parent, we can go back a single column.
	// This boolean will tell us if that happened
	BOOL addedParent = NO;

	for (NSString* parent in [commit.parents subarrayWithRange:NSMakeRange(1, [commit.parents count] -1)]) {
		int i = 0;
		BOOL was_displayed = NO;
		for (PBGitLane* column in currentLanes) {
			i++;
			if ([column isCommit: parent]) {
				[lines addObject:[PBGitGraphLine lowerLineFrom: i to: newPos color: [column index]]];
				was_displayed = YES;
				break;
			}
		}
		if (was_displayed)
			continue;
		
		// Really add this parent
		addedParent = YES;
		PBGitLane* newLane = [[PBGitLane alloc] initWithCommit:parent];
		[currentLanes addObject: newLane];
		[lines addObject:[PBGitGraphLine lowerLineFrom: [currentLanes count] to: newPos color: [newLane index]]];
	}

	previous = [[PBGraphCellInfo alloc] initWithPosition:newPos andLines:lines];
	previous.sign = commit.sign;

	// If a parent was added, we have room to not indent.
	if (addedParent)
		previous.numColumns = [currentLanes count] - 1;
	else
		previous.numColumns = [currentLanes count];

	if ([commit.parents count] > 0 && ![[commit.parents objectAtIndex:0] isEqualToString:@""])
		currentLane.sha = [commit.parents objectAtIndex:0];
	else
		[currentLanes removeObject:currentLane];

	previousLanes = currentLanes;
	commit.lineInfo = previous;
}

- (void) finalize
{
	[super finalize];
}
@end
