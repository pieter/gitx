//
//  PBGitGrapher.m
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitGrapher.h"
#import "PBGitCommit.h"

@implementation PBGitGrapher


- (void) parseCommits: (NSArray *) commits
{
	cellsInfo = [NSMutableArray arrayWithCapacity: [commits count]];
	int row = 0;

	PBGraphCellInfo* previous;
	NSMutableArray* previousLanes = [NSMutableArray array];

	for (PBGitCommit* commit in commits) {
		int i = 0, newPos = -1; 
		NSMutableArray* currentLanes = [NSMutableArray array];
		NSMutableArray* lines = [NSMutableArray array];
		BOOL didFirst = NO;

		// First, iterate over earlier columns and pass through any that don't want this commit
		if (previous != nil) {
			
			// We can't count until numColumns here, as it's only used for the width of the cell.
			for (NSString* lane in previousLanes) {
				i++;
				// This is our commit! We should do a "merge": move the line from
				// our upperMapping to their lowerMapping
				if ([lane isEqualToString:commit.sha]) {
					if (!didFirst) {
						didFirst = YES;
						[currentLanes addObject: [commit.parents objectAtIndex:0]];
						newPos = [currentLanes count];
					}
					[lines addObject: [PBGitGraphLine upperLineFrom: i to: newPos]];
				}
				else { 
					// We are not this commit.
					// Try to find an earlier column for this commit.
					int j = 0;
					BOOL found = NO;
					for (NSString* column in currentLanes) {
						j++;
						// ??? what is this?
						if (j == newPos)
							continue;
						if ([column isEqualToString: lane]) {
							// We already have a column for this commit. use it instead
							[lines addObject: [PBGitGraphLine upperLineFrom: i to: j]];
							found = YES;
							break;
						}
					}

					// We need a new column for this.
					if (!found) {
						
						// This was used as a hack to stop large lanes from drawing
						//if (previous->columns[i].color == 10)
						//	continue;
						
						[currentLanes addObject: lane];
						[lines addObject: [PBGitGraphLine upperLineFrom: [currentLanes count] to: [currentLanes count]]];
						[lines addObject: [PBGitGraphLine lowerLineFrom: [currentLanes count] to: [currentLanes count]]];
					}
				}
				// For existing columns, we always just continue straight down
				// ^^ I don't know what that means anymore :(
				[lines addObject:[PBGitGraphLine lowerLineFrom:newPos to:newPos]];
			}
		}
		
		//Add your own parents
		
		// If we already did the first parent, don't do so again
		if (!didFirst) {
			[currentLanes addObject: [commit.parents objectAtIndex:0]];
			newPos = [currentLanes count];
			[lines addObject:[PBGitGraphLine lowerLineFrom: newPos to: newPos]];
		}
		
		// Add all other parents
		
		// If we add at least one parent, we can go back a single column.
		// This boolean will tell us if that happened
		BOOL addedParent = NO;

		for (NSString* parent in [commit.parents subarrayWithRange:NSMakeRange(1, [commit.parents count] -1)]) {
			int i = 0;
			BOOL was_displayed = NO;
			for (NSString* column in currentLanes) {
				i++;
				if ([column isEqualToString: parent]) {
					[lines addObject:[PBGitGraphLine lowerLineFrom: i to: newPos]];
					was_displayed = YES;
					break;
				}
			}
			if (was_displayed)
				continue;
			
			// Really add this parent
			addedParent = YES;
			[currentLanes addObject:parent];
			[lines addObject:[PBGitGraphLine lowerLineFrom: [currentLanes count] to: newPos]];
		}
		
		++row;
		previous = [[PBGraphCellInfo alloc] initWithPosition:newPos andLines:lines];
		
		// If a parent was added, we have room to not indent.
		if (addedParent)
			previous.numColumns = [currentLanes count] - 1;
		else
			previous.numColumns = [currentLanes count];
		previousLanes = currentLanes;
		[cellsInfo addObject: previous];
	}
}

- (PBGraphCellInfo*) cellInfoForRow: (int) row
{
	return [cellsInfo objectAtIndex: row];
}

- (void) finalize
{
	free(cellsInfo);
	[super finalize];
}
@end
