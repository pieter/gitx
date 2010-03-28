//
//  PBGitHistoryList.h
//  GitX
//
//  Created by Nathan Kinsinger on 2/20/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class PBGitRepository;
@class PBGitRevSpecifier;
@class PBGitRef;
@class PBGitRevList;
@class PBGitHistoryGrapher;

@interface PBGitHistoryList : NSObject {
	PBGitRepository *repository;

	PBGitRevList *projectRevList;
	PBGitRevList *currentRevList;

	NSString *lastSHA;
	NSSet *lastRefSHAs;
	NSInteger lastBranchFilter;
	PBGitRef *lastRemoteRef;
	BOOL resetCommits;
	BOOL shouldReloadProjectHistory;
	NSDate *updatedGraph;

	PBGitHistoryGrapher *grapher;
	NSOperationQueue *graphQueue;

	NSMutableArray *commits;
	BOOL isUpdating;
}

- (id) initWithRepository:(PBGitRepository *)repo;
- (void) forceUpdate;
- (void) updateHistory;

- (void) addCommitsFromArray:(NSArray *)array;


@property (retain) PBGitRevList *projectRevList;
@property (retain) NSMutableArray *commits;
@property (readonly) NSArray *projectCommits;
@property (assign) BOOL isUpdating;
@property (retain) NSDate *updatedGraph;

@end
