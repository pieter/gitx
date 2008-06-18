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
	cellsInfo = malloc(sizeof(struct PBGitGraphCellInfo) * [commits count]);
	memset(cellsInfo, 0, sizeof(struct PBGitGraphCellInfo) * [commits count]);
	
	int row = 0;

	struct PBGitGraphCellInfo *previous = nil;
	for (PBGitCommit* commit in commits) {
		struct PBGitGraphCellInfo *info = &(cellsInfo[row]);
		info->commit = commit.sha;
		info->numColumns = 0;

		int i = 0, newPos = -1; 
		for (i = 0; i < PBGitMaxColumns; i++) {
			info->lowerMapping[i] = -1;
			info->upperMapping[i] = -1;
		}
		
		BOOL didFirst = NO;
		// First, iterate over earlier columns and pass through any that don't want this commit
		if (previous != nil) {
			
			// We can't count until numColumns here, as it's only used for the width of the cell.
			for (i = 0; i < PBGitMaxColumns; i++) {
				if ((previous->columns[i].commit) == nil)
					continue;
				
				// This is our commit! We should do a "merge": move the line from
				// our upperMapping to their lowerMapping
				if ([previous->columns[i].commit isEqualToString:info->commit]) {
					if (!didFirst) {
						didFirst = YES;
						info->position = info->numColumns++;
						info->columns[info->position].commit = [commit.parents objectAtIndex:0];
					}
					newPos = info->position;
					info->upperMapping[i] = newPos;
				}
				else { 
					// We are not this commit.
					// Try to find an earlier column for this commit.
					int j;
					BOOL found = NO;
					for (j = 0; j < info->numColumns; j++) {
						if (j == info->position)
							continue;
						if ([previous->columns[i].commit isEqualToString: info->columns[j].commit]) {
							// We already have a column for this commit. use it instead
							newPos = j;
							info->upperMapping[previous->lowerMapping[i]] = newPos;
							found = YES;
							break;
						}
					}
					// We need a new column for this.
					if (!found) {
						newPos = info->numColumns++;
						info->columns[newPos] = previous->columns[i];
						info->upperMapping[newPos] = newPos;
					}
				}
				// For existing columns, we always just continue straight down
				info->lowerMapping[newPos] = newPos;
			}
		}
		
		//Add your own parents
		
		// If we already did the first parent, don't do so again
		if (!didFirst) {
			info->position = info->numColumns++;
			info->columns[info->position].commit = [commit.parents objectAtIndex:0];
			info->lowerMapping[info->position] = info->position;
		}
		
		// Add all other parents
		
		// If we add at least one parent, we can go back a single column.
		// This boolean will tell us if that happened
		BOOL addedParent = NO;

		for (NSString* parent in [commit.parents subarrayWithRange:NSMakeRange(1, [commit.parents count] -1)]) {
			int i;
			BOOL was_displayed = NO;
			for (i = 0; i < info->numColumns; i++)
				if ([info->columns[i].commit isEqualToString: parent]) {
					// TODO!
					// !!! BUG
					// This overwrites an existing mapping.
					// We should instead have the possibility
					// to add multiple lower mappings
					// As we don't have that now, pieces of the graph are missing
					info->lowerMapping[i] = info->position;
					was_displayed = YES;
					break;
				}
			if (was_displayed)
				continue;
			
			// Really add this parent
			addedParent = YES;
			info->columns[info->numColumns++].commit = parent;
			info->lowerMapping[info->numColumns -1] = info->position;
		}
		
		// A parent was added, so we have room to not indent.
		if (addedParent)
			info->numColumns--;
		previous = info;
		++row;
	}
}
- (struct PBGitGraphCellInfo) cellInfoForRow: (int) row
{
	return cellsInfo[row];
}

- (void) finalize
{
	free(cellsInfo);
	[super finalize];
}
@end
