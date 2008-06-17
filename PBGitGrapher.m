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
static NSColor** PBGitGraphColors;

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
		BOOL didFirst = NO;
		// First, iterate over earlier columns and pass through any that don't want this commit
		if (previous != nil) {
			for (i = 0; i < 10; i++) {
				if ((previous->columns[i].commit) == nil)
					continue;
				if ([previous->columns[i].commit isEqualToString:info->commit]) {
					if (!didFirst) {
						didFirst = YES;
						info->position = info->numColumns++;
						info->columns[info->position].commit = [commit.parents objectAtIndex:0];
						info->columns[info->position].color = previous->columns[i].color;
					}
					newPos = info->position;
				}
				else {
					newPos = info->numColumns++;
					info->columns[newPos] = previous->columns[i];
					if (newPos > 1)
						info->columns[newPos].color = (info->columns[newPos - 1].color + 1) % 4;
				}

				info->upperMapping[newPos] = i;
				if (previous)
					previous->lowerMapping[i] = newPos;
					
			}
		}
		
		//Add your own parents!
		BOOL doFirst = YES;

		for (NSString* parent in commit.parents) {
			if (doFirst) {
				doFirst = NO;
				if (didFirst)
					continue;
				info->position = info->numColumns++;
				info->columns[info->position].commit = parent;
				continue;
			}

			info->columns[info->numColumns++].commit = parent;
		}
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
