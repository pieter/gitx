//
//  PBGitHistoryGrapher.h
//  GitX
//
//  Created by Nathan Kinsinger on 2/20/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PBGitGrapher;


@interface PBGitHistoryGrapher : NSObject {
	id delegate;

	NSMutableSet *searchSHAs;
	PBGitGrapher *grapher;
	BOOL viewAllBranches;
}

- (id) initWithBaseCommits:(NSSet *)commits viewAllBranches:(BOOL)viewAll delegate:(id)theDelegate;
- (void) graphCommits:(NSArray *)revList;

@end
