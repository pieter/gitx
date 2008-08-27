//
//  PBGitGrapher.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitCommit.h"


struct PBGitGraphColumn {
	NSString* commit; // Commit that we're looking for
	int color;
};


#define PBGitMaxColumns 100

struct PBGitGraphCellInfo {
	struct PBGitGraphColumn columns[PBGitMaxColumns];
	int upperMapping[PBGitMaxColumns]; //How are the offsets compared to previous cell?
	int lowerMapping[PBGitMaxColumns]; //How are the offsets compared to this cell?
	int position;
	NSString* commit; // Commit in cell
	int numColumns;
	int numNewColumns;
};

void add_commit_to_graph(struct PBGitGraphCellInfo* info, NSString* parent, int* mapping_index);

typedef struct PBGitGraphCellInfo PBGitCellInfo;


@interface PBGitGrapher : NSObject {
	PBGitCellInfo* cellsInfo;
}

- (void) parseCommits: (NSArray *) array;
- (struct PBGitGraphCellInfo) cellInfoForRow: (int) row;
@end
