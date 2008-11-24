//
//  PBGitGrapher.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

extern "C" {
#import "git/oid.h"
}

#import "PBGitGrapher.h"
#import "PBGitCommit.h"
#import "PBGitLane.h"
#import "PBGitGraphLine.h"
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

void add_line(struct PBGitGraphLine *lines, int *nLines, int upper, int from, int to, int index)
{
	// TODO: put in one thing
	struct PBGitGraphLine a = { upper, from, to, index };
	lines[(*nLines)++] = a;
}

- (void) decorateCommit: (PBGitCommit *) commit
{
	int i = 0, newPos = -1;
	std::vector<PBGitLane *> *currentLanes = new std::vector<PBGitLane *>;
	std::vector<PBGitLane *> *previousLanes = (std::vector<PBGitLane *> *)pl;

	int maxLines = (previousLanes->size() + [commit.parents count] + 2) * 3;
	struct PBGitGraphLine *lines = (struct PBGitGraphLine *)malloc(sizeof(struct PBGitGraphLine) * maxLines);
	int currentLine = 0;

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
					add_line(lines, &currentLine, 1, i, newPos,(*it)->index());
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

			if (currentLane)
				add_line(lines, &currentLine, 0, newPos, newPos,(*it)->index());
			else
				add_line(lines, &currentLine, 0, newPos, newPos, 0);
		}
	}
	//Add your own parents

	// If we already did the first parent, don't do so again
	if (!didFirst && currentLanes->size() < MAX_LANES) {
		PBGitLane *newLane = new PBGitLane([commit.parents objectAtIndex:0]);
		currentLanes->push_back(newLane);
		newPos = currentLanes->size();
		add_line(lines, &currentLine, 0, newPos, newPos, newLane->index());
	}

	// Add all other parents

	// If we add at least one parent, we can go back a single column.
	// This boolean will tell us if that happened
	BOOL addedParent = NO;

	for (NSString *parent in [commit.parents subarrayWithRange:NSMakeRange(1, [commit.parents count] -1)]) {
		int i = 0;
		BOOL was_displayed = NO;
		std::vector<PBGitLane *>::iterator it = currentLanes->begin();
		for (; it < currentLanes->end(); ++it) {
			i++;
			if ((*it)->isCommit(parent)) {
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
		PBGitLane *newLane = new PBGitLane(parent);
		currentLanes->push_back(newLane);
		add_line(lines, &currentLine, 0, currentLanes->size(), newPos, newLane->index());
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
