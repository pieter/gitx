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
#import "PBGitGraphLine.h"
#import "PBGitRepository.h"
#import <list>
#import "git/oid.h"

using namespace std;

@implementation PBGitGrapher

#define MAX_LANES 32

- initWithRepository:(PBGitRepository *)repo
{
	previousLanes = new std::list<PBGitLane *>;
	currentLanes = new std::list<PBGitLane *>;

	PBGitLane::resetColors();
	return self;
}

inline void add_line(struct PBGitGraphLine *lines, int *nLines, int upper, int from, int to, int index)
{
	// TODO: put in one thing
	struct PBGitGraphLine a = { upper, from, to, index };
	lines[(*nLines)++] = a;
}

- (void) decorateCommit: (PBGitCommit *) commit
{
	int i = 0, newPos = -1;

	currentLanes->clear();
	int maxLines = (previousLanes->size() + commit.nParents + 2) * 2;
	struct PBGitGraphLine *lines = (struct PBGitGraphLine *)malloc(sizeof(struct PBGitGraphLine) * maxLines);
	int currentLine = 0;

	PBGitLane *currentLane = NULL;
	BOOL didFirst = NO;
	
	// We can't count until numColumns here, as it's only used for the width of the cell.
	std::list<PBGitLane *>::iterator it = previousLanes->begin();
	for (; it != previousLanes->end(); ++it) {
		i++;
		// This is our commit! We should do a "merge": move the line from
		// our upperMapping to their lowerMapping
		if ((*it)->commit == commit) {
			if (!didFirst) {
				didFirst = YES;
				currentLanes->push_back(*it);
				currentLane = currentLanes->back();
				newPos = currentLanes->size();
				add_line(lines, &currentLine, 1, i, newPos,(*it)->index);
				if (commit.nParents) // continue straight down if the commit has parents
					add_line(lines, &currentLine, 0, newPos, newPos,(*it)->index);
			}
			else {
				add_line(lines, &currentLine, 1, i, newPos,(*it)->index);
				delete *it;
			}
		}
		else {
			// We are not this commit. Continue down
			currentLanes->push_back(*it);
			add_line(lines, &currentLine, 1, i, currentLanes->size(),(*it)->index);
			add_line(lines, &currentLine, 0, currentLanes->size(), currentLanes->size(), (*it)->index);
		}
	}

	//Add your own parents

	// Create a lane for our first parent, if we haven't done so.
	if (!didFirst && currentLanes->size() < MAX_LANES && [[commit parents] count]) {
		PBGitLane *newLane = new PBGitLane([[commit parents] objectAtIndex:0]);
		currentLanes->push_back(newLane);
		newPos = currentLanes->size();
		add_line(lines, &currentLine, 0, newPos, newPos, newLane->index);
	}

	// Add all other parents

	// If we add at least one parent, we can go back a single column.
	// This boolean will tell us if that happened
	BOOL addedParent = NO;

	BOOL first = true;
	for (PBGitCommit *parent in [commit parents]) {
		if (first)
		{
			first = false;
			continue;
		}
		int i = 0;
		BOOL was_displayed = NO;
		std::list<PBGitLane *>::iterator it = currentLanes->begin();
		for (; it != currentLanes->end(); ++it) {
			i++;
			if ((*it)->commit == parent) {
				add_line(lines, &currentLine, 0, i, newPos,(*it)->index);
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
		add_line(lines, &currentLine, 0, currentLanes->size(), newPos, newLane->index);
	}

	previous = [[PBGraphCellInfo alloc] initWithPosition:newPos andLines:lines];
	if (currentLine > maxLines)
		NSLog(@"Number of lines: %i vs allocated: %i", currentLine, maxLines);

	previous.nLines = currentLine;
	previous.sign = commit.sign;

	// If a parent was added, we have room to not indent.
	if (addedParent)
		previous.numColumns = currentLanes->size() - 1;
	else
		previous.numColumns = currentLanes->size();

	// Update the current lane to point to the new parent
	if (currentLane && [[commit parents] count] > 0)
		currentLane->commit = [[commit parents] objectAtIndex: 0];
	else
		currentLanes->remove(currentLane);

	previousLanes->swap(*currentLanes);
	commit.lineInfo = previous;
}

- (void) finalize
{
	std::list<PBGitLane *>::iterator it = previousLanes->begin();
	for (; it != previousLanes->end(); ++it)
		delete *it;

	delete previousLanes;

	[super finalize];
}
@end
