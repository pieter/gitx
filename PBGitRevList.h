//
//  PBGitRevList.h
//  GitX
//
//  Created by Pieter de Bie on 17-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PBGitRepository;
@class PBGitGrapher;

@interface PBGitRevList : NSObject {
	NSMutableArray *commits;
	NSMutableArray *newCommits;
	PBGitRepository *repository;
	PBGitGrapher *grapher;
	NSString* lastSha;
	int commitsLoaded;
}

- initWithRepository:(PBGitRepository *)repo;
- (void)readCommitsForce:(BOOL)force;
- (void)reload;
- (void)linearizeCommits;

@property (retain) NSMutableArray *commits;

@end
