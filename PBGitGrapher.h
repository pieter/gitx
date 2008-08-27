//
//  PBGitGrapher.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitCommit.h"
#import "PBGitGraphLine.h"
#import "PBGraphCellInfo.h"

struct PBGitGraphColumn {
	NSString* commit; // Commit that we're looking for
	int color;
};


#define PBGitMaxColumns 100

@interface PBGitGrapher : NSObject {
	NSMutableArray* cellsInfo;
}

- (void) parseCommits: (NSArray *) array;
- (PBGraphCellInfo*) cellInfoForRow: (int) row;
@end
