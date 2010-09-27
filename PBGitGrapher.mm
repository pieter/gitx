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
#import <list>
#import "git/oid.h"

using namespace std;

@implementation PBGitGrapher

#define MAX_LANES 32

- (id) initWithRepository: (PBGitRepository*) repo
{
	pl = new std::list<PBGitLane *>;

	PBGitLane::resetColors();
	return self;
}

void add_line(struct PBGitGraphLine *lines, int *nLines, int upper, int from, int to, int index)
{
	// TODO: put in one thing
	struct PBGitGraphLine a = { upper, from, to, index };
	lines[(*nLines)++] = a;
}

- (void) decorateCommit: (PBGitCommit *) commit
{
	int i = 0, newPos = -1;
	std::list<PBGitLane *> *currentLanes = new std::list<PBGitLane *>;
	std::list<PBGitLane *> *previousLanes = (std::list<PBGitLane *> *)pl;
	NSArray *parents = [commit parents];
	int nParents = [parents count];

	int maxLines = (previousLanes->size() + nParents + 2) * 2;
	struct PBGitGraphLine *lines = (struct PBGitGraphLine *)malloc(sizeof(struct PBGitGraphLine) * maxLines);
	int currentLine = 0;

	PBGitLane *currentLane = NULL;
	BOOL didFirst = NO;
	git_oid commit_oid = [[commit sha] oid];
	
	// First, iterate over earlier columns and pass through any that don't want this commit
	if (previous != nil) {
		// We can't count until numColumns here, as it's only used for the width of the cell.
		std::list<PBGitLane *>::iterator it = previousLanes->begin();
		for (; it != previousLanes->end(); ++it) {
			i++;
			// This is our commit! We should do a "merge": move the line from
			// our upperMapping to their lowerMapping
			if ((*it)->isCommit(commit_oid)) {
				if (!didFirst) {
					didFirst = YES;
					currentLanes->push_back(*it);
					currentLane = currentLanes->back();
					newPos = currentLanes->size();
					add_line(lines, &currentLine, 1, i, newPos,(*it)->index());
					if (nParents)
						add_line(lines, &currentLine, 0, newPos, newPos,(*it)->index());
				}
				else {
					add_line(lines, &currentLine, 1, i, newPos,(*it)->index());
					delete *it;
				}
			}
			else {
				// We are not this commit.
				currentLanes->push_back(*it);
				add_line(lines, &currentLine, 1, i, currentLanes->size(),(*it)->index());
				add_line(lines, &currentLine, 0, currentLanes->size(), currentLanes->size(), (*it)->index());
			}
			// For existing columns, we always just continue straight down
			// ^^ I don't know what that means anymore :(

		}
	}
	//Add your own parents

	// If we already did the first parent, don't do so again
	if (!didFirst && currentLanes->size() < MAX_LANES && nParents) {
		git_oid parentOID = [[parents objectAtIndex:0] oid];
		PBGitLane *newLane = new PBGitLane(&parentOID);
		currentLanes->push_back(newLane);
		newPos = currentLanes->size();
		add_line(lines, &currentLine, 0, newPos, newPos, newLane->index());
	}

	// Add all other parents

	// If we add at least one parent, we can go back a single column.
	// This boolean will tell us if that happened
	BOOL addedParent = NO;

	int parentIndex = 0;
	for (parentIndex = 1; parentIndex < nParents; ++parentIndex) {
		git_oid parentOID = [[parents objectAtIndex:parentIndex] oid];
		int i = 0;
		BOOL was_displayed = NO;
		std::list<PBGitLane *>::iterator it = currentLanes->begin();
		for (; it != currentLanes->end(); ++it) {
			i++;
			if ((*it)->isCommit(parentOID)) {
				add_line(lines, &currentLine, 0, i, newPos,(*it)->index());
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
		PBGitLane *newLane = new PBGitLane(&parentOID);
		currentLanes->push_back(newLane);
		add_line(lines, &currentLine, 0, currentLanes->size(), newPos, newLane->index());
	}

	if (commit.lineInfo) {
		previous = commit.lineInfo;
		previous.position = newPos;
		previous.lines = lines;
	}
	else
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
	if (currentLane && nParents > 0)
		currentLane->setSha([[parents objectAtIndex:0] oid]);
	else
		currentLanes->remove(currentLane);

	delete previousLanes;

	pl = currentLanes;
	commit.lineInfo = previous;
}

- (void) finalize
{
	std::list<PBGitLane *> *lanes = (std::list<PBGitLane *> *)pl;
	std::list<PBGitLane *>::iterator it = lanes->begin();
	for (; it != lanes->end(); ++it)
		delete *it;

	delete lanes;

	[super finalize];
}
@end
