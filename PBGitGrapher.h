//
//  PBGitGrapher.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "list"

#import "PBGitCommit.h"
#import "PBGitGraphLine.h"
#import "PBGraphCellInfo.h"
#import "PBGitLane.h"

@class PBGitRepository;

@interface PBGitGrapher : NSObject {
	PBGraphCellInfo *previous;
	std::list<PBGitLane *> *previousLanes;
	std::list<PBGitLane *> *currentLanes;
	int curLane;
}

- initWithRepository:(PBGitRepository *)repo;
- (void)decorateCommit:(PBGitCommit *)commit;
@end
