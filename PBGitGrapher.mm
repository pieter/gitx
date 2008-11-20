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
#import <vector>

using namespace std;

@implementation PBGitGrapher

#define MAX_LANES 32

- (id) initWithRepository: (PBGitRepository*) repo
{
	refs = repo.refs;
	repository = repo;
	pl = new std::vector<PBGitLane>;

	PBGitLane::resetColors();
	//[PBGitLane resetColors];

	return self;
}

- (void) decorateCommit: (PBGitCommit *) commit
{
	//NSLog(@"Decoriting commit %@", commit.sha);
	int i = 0, newPos = -1;
	std::vector<PBGitLane *> *currentLanes = new std::vector<PBGitLane *>;
	std::vector<PBGitLane *> *previousLanes = (std::vector<PBGitLane *> *)pl;

	NSMutableArray* lines = [NSMutableArray array];
	PBGitLane *currentLane = NULL;
	BOOL didFirst = NO;
	
	// First, iterate over earlier columns and pass through any that don't want this commit
	if (previous != nil) {
		// We can't count until numColumns here, as it's only used for the width of the cell.
		std::vector<PBGitLane *>::iterator it = previousLanes->begin();
		for (; it < previousLanes->end(); ++it) {
			i++;
			// This is our commit! We should do a "merge": move the line from
			// our upperMapping to their lowerMapping

			if ((*it)->isCommit([commit sha])) {
				if (!didFirst) {
					didFirst = YES;
					currentLanes->push_back(*it);
					currentLane = currentLanes->back();
					newPos = currentLanes->size();
					[lines addObject: [PBGitGraphLine upperLineFrom: i to: newPos color: (*it)->index()]];
				}
				else {
					[lines addObject: [PBGitGraphLine upperLineFrom: i to: newPos color: (*it)->index()]];
					delete *it;
				}
			}
			else {
				// We are not this commit.
				// Try to find an earlier column for this commit.
				int j = 0;
				BOOL found = NO;
				std::vector<PBGitLane *>::iterator it2 = currentLanes->begin();
				for (; it2 < currentLanes->end(); ++it2) {
					j++;
					// ??? what is this?
//						if (j == newPos)
//							continue;
					if ((*it)->isCommit([commit sha])) {
						// We already have a column for this commit. use it instead
						[lines addObject: [PBGitGraphLine upperLineFrom: i to: j color: (*it)->index()]];
						found = YES;
						break;
					}
				}

				// We need a new column for this.
				if (found) {
					//NSLog(@"Need to delete");
				} else {
					//NSLog(@"Found another");
					currentLanes->push_back(*it);
					[lines addObject: [PBGitGraphLine upperLineFrom: i to: currentLanes->size() color: (*it)->index()]];
					[lines addObject: [PBGitGraphLine lowerLineFrom: currentLanes->size() to: currentLanes->size() color: (*it)->index()]];
				}
			}
			// For existing columns, we always just continue straight down
			// ^^ I don't know what that means anymore :(

			if (currentLane)
				[lines addObject:[PBGitGraphLine lowerLineFrom:newPos to:newPos color: currentLane->index()]];
			else
				[lines addObject:[PBGitGraphLine lowerLineFrom:newPos to:newPos color: 0]];
		}
	}
	//Add your own parents

	// If we already did the first parent, don't do so again
	if (!didFirst && currentLanes->size() < MAX_LANES) {
		PBGitLane *newLane = new PBGitLane([commit.parents objectAtIndex:0]);
		currentLanes->push_back(newLane);
		newPos = currentLanes->size();
		[lines addObject:[PBGitGraphLine lowerLineFrom: newPos to: newPos color: newLane->index()]];
	}

	// Add all other parents

	// If we add at least one parent, we can go back a single column.
	// This boolean will tell us if that happened
	BOOL addedParent = NO;

	for (NSString* parent in [commit.parents subarrayWithRange:NSMakeRange(1, [commit.parents count] -1)]) {
		int i = 0;
		BOOL was_displayed = NO;
		std::vector<PBGitLane *>::iterator it = currentLanes->begin();
		for (; it < currentLanes->end(); ++it) {
			i++;
			if ((*it)->isCommit(parent)) {
				[lines addObject:[PBGitGraphLine lowerLineFrom: i to: newPos color: (*it)->index()]];
				was_displayed = YES;
				break;
			}
		}
		if (was_displayed)
			continue;
		
		if (currentLanes->size() >= MAX_LANES)
			break;

		// Really add this parent
		addedParent = YES;
		PBGitLane *newLane = new PBGitLane(parent);
		currentLanes->push_back(newLane);
		[lines addObject:[PBGitGraphLine lowerLineFrom: currentLanes->size() to: newPos color: newLane->index()]];
	}

	previous = [[PBGraphCellInfo alloc] initWithPosition:newPos andLines:lines];
	previous.sign = commit.sign;

	// If a parent was added, we have room to not indent.
	if (addedParent)
		previous.numColumns = currentLanes->size() - 1;
	else
		previous.numColumns = currentLanes->size();

	// Update the current lane to point to the new parent
	if (currentLane && [commit.parents count] > 0 && ![[commit.parents objectAtIndex:0] isEqualToString:@""])
		currentLane->setSha([commit.parents objectAtIndex:0]);
	//	else
	//		[currentLanes removeObject:currentLane];

	delete previousLanes;

	pl = currentLanes;
	commit.lineInfo = previous;
}

- (void) finalize
{
	[super finalize];
}
@end
